defmodule MySciNetWeb.StorageController do
  use MySciNetWeb, :controller

  @valid_project_id ~r/\A[a-zA-Z0-9_-]+\z/

  def index(conn, _params) do
    user_storage(conn, %{"id" => conn.assigns.current_user.username})
  end

  def user_storage(conn, %{"id" => username}) do
    # gather allocations for user and filter allowed prefixes
    allocations =
      case MySciNetWeb.AllocationController.get_allocations_for_user(username) do
        {:ok, allocs} ->
          allocs
          |> Enum.flat_map(fn {_, a} -> a end)
          |> Enum.uniq()

        error ->
          dbg(error)
          []
      end

    {:ok, %{groups: groups}} = MySciNet.LDAP.user_info(username)
    redis_keys = storage_keys(username, allocations, groups)

    case MySciNet.Redis.hgetalls(redis_keys, fn k, v ->
           case k do
             "name" -> v
             "state" -> v
             "path" -> v
             _ -> String.to_integer(v)
           end
         end) do
      {:ok, results} ->
        filtered = Enum.reject(results, fn r -> map_size(r) == 0 end)
        render(conn, :index, storage: filtered)

      error ->
        dbg(error)

        conn
        |> put_flash(:error, "Failed to retrieve storage information.")
        |> render(:index)
    end
  end

  def project(conn, %{"id" => project_id}) do
    with_project(conn, project_id, fn ->
      render(conn, :project, project_id: project_id)
    end)
  end

  def project_users_csv(conn, %{"id" => project_id}) do
    with_project(conn, project_id, fn ->
      case System.cmd("/venv/bin/vast_usage_by_user.py", ["/trillium_project/#{project_id}"]) do
        {output, 0} ->
          conn
          |> put_resp_content_type("text/csv")
          |> put_resp_header("cache-control", "max-age=3600, private")
          |> send_resp(:ok, enrich_csv_with_usernames(output))

        {_output, _code} ->
          conn
          |> put_status(:internal_server_error)
          |> text("error collecting project usage")
      end
    end)
  end

  defp with_project(conn, project_id, fun) do
    cond do
      not (project_id =~ @valid_project_id) ->
        conn |> put_status(:bad_request) |> text("invalid project id")

      not authorized_for_project?(conn, project_id) ->
        conn |> put_status(:not_found) |> text("not found or not permitted")

      true ->
        fun.()
    end
  end

  defp authorized_for_project?(conn, project_id) do
    MySciNetWeb.Permissions.is_superuser?(conn) or
      case MySciNetWeb.AllocationController.get_allocations_for_user(
             conn.assigns.current_user.username
           ) do
        {:ok, allocs} ->
          allocs
          |> Enum.flat_map(fn {_, a} -> a end)
          |> Enum.member?(project_id)

        _ ->
          false
      end
  end

  defp enrich_csv_with_usernames(csv_text) do
    [header | rows] = String.split(String.trim(csv_text), "\n")
    uid_numbers = Enum.map(rows, fn row -> row |> String.split(",", parts: 2) |> hd() end)

    username_map =
      case MySciNet.LDAP.users_by_uid_numbers(uid_numbers) do
        {:ok, map} -> map
        _ -> %{}
      end

    [_, rest_header] = String.split(header, ",", parts: 2)

    new_rows =
      Enum.map(rows, fn row ->
        [uid, rest] = String.split(row, ",", parts: 2)
        "#{uid},#{Map.get(username_map, uid, "")},#{rest}"
      end)

    Enum.join(["uid,username," <> rest_header | new_rows], "\n") <> "\n"
  end

  defp storage_keys(username, allocations, groups) do
    projects =
      for(
        alloc <- allocations,
        do: "du:trillium_project:#{alloc}"
      )
      |> Enum.sort(:desc)

    # commercial users have special directories
    specials =
      ["du:trillium_home:#{String.first(username)}:#{username}"] ++
        for(
          group <- groups,
          do: "du:trillium_scratch:#{String.first(group)}:#{group}"
        ) ++
        for(
          group <- groups,
          do: "du:trillium_project:#{String.first(group)}:#{group}"
        )

    ["du:trillium_home:#{username}", "du:trillium_scratch:#{username}"] ++ projects ++ specials
  end
end

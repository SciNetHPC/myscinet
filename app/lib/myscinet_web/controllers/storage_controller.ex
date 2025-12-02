defmodule MySciNetWeb.StorageController do
  use MySciNetWeb, :controller

  def index(conn, _params) do
    user_storage(conn, %{"id" => conn.assigns.current_user.username})
  end

  def user_storage(conn, %{"id" => username}) do
    # gather allocations for user and filter allowed prefixes
    allocations =
      case MySciNetWeb.AllocationController.get_allocations_for_user(username) do
        {:ok, allocs} ->
          allocs
          |> Enum.map(fn {_, a} -> a end)
          |> List.flatten()
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

  defp storage_keys(username, allocations, groups) do
    projects =
      for(
        alloc <- allocations,
        do: "du:trillium_project:#{alloc}"
      )
      |> Enum.sort()
      |> Enum.reverse()

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

defmodule MySciNetWeb.StorageController do
  use MySciNetWeb, :controller

  def index(conn, _params) do
    username = conn.assigns.current_user.username

    # gather allocations for user and filter allowed prefixes
    allocations =
      conn.assigns.current_user.groups
      |> Enum.filter(&String.match?(&1, ~r/^(def-|rrg-|rpp-|ctb-)/))

    redis_keys = storage_keys(username, allocations)

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

  defp storage_keys(username, allocations) do
    projects =
      for(
        alloc <- allocations,
        do: "du:trillium_project:#{alloc}"
      )
      |> Enum.sort()
      |> Enum.reverse()

    ["du:trillium_home:#{username}", "du:trillium_scratch:#{username}"] ++ projects
  end
end

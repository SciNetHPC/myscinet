defmodule MySciNetWeb.AllocationController do
  use MySciNetWeb, :controller

  @clusters ["trillium", "grillium", "balam"]

  def get_allocations_for_user(username) do
    cmds = for cluster <- @clusters, do: ["GET", "#{cluster}:allocation:accounts:#{username}"]

    case MySciNet.Redis.pipeline(cmds) do
      {:ok, results} ->
        allocs =
          for result <- results,
              do:
                result
                |> to_string()
                |> String.split()
                |> Enum.sort()

        {:ok, Enum.zip(@clusters, allocs)}

      error ->
        error
    end
  end

  def get_allocation(cluster, name) do
    keys = ["#{cluster}:allocation:#{name}", "#{cluster}:allocation:#{name}:sshare"]

    case MySciNet.Redis.hgetalls(keys, fn _, v -> String.to_float(v) end) do
      {:ok, [overall, sshare]} ->
        {:ok, cluster, overall, sshare}

      error ->
        error
    end
  end

  def index(conn, _params) do
    case get_allocations_for_user(conn.assigns.current_user.username) do
      {:ok, allocs} ->
        render(conn, :index, allocations: allocs)

      error ->
        dbg(error)

        conn
        |> put_flash(:error, "Error retrieving allocations")
        |> render(:index, allocations: [])
    end
  end

  def show(conn, %{"cluster" => cluster, "id" => id}) do
    case get_allocation(cluster, id) do
      {:ok, cluster, overall, sshare} ->
        render(conn, :show, cluster: cluster, allocation: id, overall: overall, sshare: sshare)

      error ->
        dbg(error)

        conn
        |> put_flash(:error, "Allocation not found")
        |> redirect(to: ~p"/allocations")
    end
  end
end

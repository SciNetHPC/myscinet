defmodule MySciNetWeb.AllocationController do
  use MySciNetWeb, :controller
  require MySciNetWeb.Permissions
  alias MySciNetWeb.Clusters

  def get_allocations_for_user(username) do
    clusters = Clusters.get_clusters()

    redis_cmds =
      for cluster <- clusters,
          do: ["GET", "#{cluster.slug_redis}:allocation:accounts:#{username}"]

    case MySciNet.Redis.pipeline(redis_cmds) do
      {:ok, results} ->
        allocs =
          for result <- results,
              do:
                result
                |> to_string()
                |> String.split()
                |> Enum.sort()

        Enum.zip(clusters, allocs)
        |> Enum.filter(fn {_, allocs} -> allocs != [] end)
        |> then(&{:ok, &1})

      error ->
        error
    end
  end

  def get_allocation(cluster_slug, name) do
    cluster = Clusters.get_cluster(cluster_slug)

    key = "#{cluster.slug_redis}:allocation:#{name}"
    keys = [key, "#{key}:sshare"]

    case MySciNet.Redis.hgetalls(keys, fn _, v ->
           case v do
             # 0/0
             "Infinity" -> 0.0
             other -> String.to_float(other)
           end
         end) do
      # Explicitly detect both-empty maps as not found
      {:ok, [overall, sshare]}
      when is_map(overall) and is_map(sshare) and map_size(overall) == 0 and map_size(sshare) == 0 ->
        {:error, :not_found}

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
    authz = id in conn.assigns.current_user.groups or MySciNetWeb.Permissions.is_staff_user?(conn)

    with true <- authz,
         {:ok, cluster, overall, sshare} <- get_allocation(cluster, id) do
      render(conn, :show, cluster: cluster, allocation: id, overall: overall, sshare: sshare)
    else
      error ->
        dbg(error)

        conn
        |> put_flash(:error, "Allocation not found or permission denied: #{cluster}/#{id}")
        |> redirect(to: ~p"/allocations")
    end
  end
end

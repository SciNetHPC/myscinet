defmodule MySciNetWeb.PageController do
  use MySciNetWeb, :controller
  alias MySciNetWeb.Clusters

  defp string_to_float(s) do
    case Float.parse(s) do
      {f, _} -> f
      :error -> -0.0
    end
  end

  defp parse_cluster_val("nodesRunning", sval), do: string_to_float(sval)
  defp parse_cluster_val(_, sval), do: String.to_integer(sval)

  defp get_clusters(clusters) do
    cluster_keys = for cluster <- clusters, do: "cluster:#{cluster.slug_redis}"
    case MySciNet.Redis.hgetalls(cluster_keys, &parse_cluster_val/2) do
      {:ok, clusters_stats} ->
        clusters_stats_with_logins =
          for {cluster, cluster_stats} <- Enum.zip(clusters, clusters_stats) do
            # Fetch login node statuses
            login_keys = for login <- cluster.logins, do: "#{login}:stats"
            login_stats = case MySciNet.Redis.hgetalls(login_keys, fn _, v -> String.to_float(v) end) do
              {:ok, results} -> results
              _ -> for _ <- cluster.logins, do: nil
            end
            cluster |> Map.merge(cluster_stats) |> Map.put(:login_stats, login_stats)
          end
        {:ok, clusters_stats_with_logins}
      error ->
        error
    end
  end

  def home(conn, _params) do
    case get_clusters(Clusters.get_clusters()) do
      {:ok, clusters} ->
        conn
        |> assign(:clusters, clusters)
        |> render(:home)
      _ ->
        conn
        |> assign(:clusters, [])
        |> put_flash(:error, "Failed to load clusters")
        |> render(:home)
    end
  end
end

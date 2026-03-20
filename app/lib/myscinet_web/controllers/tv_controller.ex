defmodule MySciNetWeb.TvController do
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
        clusters_with_logins =
          for {cluster, cluster_stats} <- Enum.zip(clusters, clusters_stats) do
            login_keys = for login <- cluster.logins, do: "#{login}:stats"

            login_stats =
              case MySciNet.Redis.hgetalls(login_keys, fn _, v -> String.to_float(v) end) do
                {:ok, results} -> results
                _ -> for _ <- cluster.logins, do: nil
              end

            cluster |> Map.merge(cluster_stats) |> Map.put(:login_stats, login_stats)
          end

        {:ok, clusters_with_logins}

      error ->
        error
    end
  end

  def index(conn, _params) do
    now_unix = DateTime.utc_now() |> DateTime.to_unix()

    case get_clusters(Clusters.get_clusters()) do
      {:ok, clusters} ->
        conn
        |> assign(:clusters, clusters)
        |> assign(:now_unix, now_unix)
        |> render(:index)

      _ ->
        conn
        |> assign(:clusters, [])
        |> assign(:now_unix, now_unix)
        |> render(:index)
    end
  end
end

defmodule MySciNet.ClusterStats do
  defp string_to_float(s) do
    case Float.parse(s) do
      {f, _} -> f
      :error -> -0.0
    end
  end

  defp parse_cluster_val("nodesRunning", sval), do: string_to_float(sval)
  defp parse_cluster_val(_, sval), do: String.to_integer(sval)

  defp parse_login_val("nologin", sval), do: sval == "1"
  defp parse_login_val(_, sval), do: String.to_float(sval)

  def get_vast do
    case MySciNet.Redis.hgetalls(["vast:clusters"], fn _, v -> string_to_float(v) end) do
      {:ok, [vast]} -> {:ok, vast}
      _ -> :error
    end
  end

  def get_clusters(clusters) do
    cluster_keys = for cluster <- clusters, do: "cluster:#{cluster.slug_redis}"

    case MySciNet.Redis.hgetalls(cluster_keys, &parse_cluster_val/2) do
      {:ok, clusters_stats} ->
        clusters_with_logins =
          for {cluster, cluster_stats} <- Enum.zip(clusters, clusters_stats) do
            login_keys = for login <- cluster.logins, do: "#{login}:stats"

            login_stats =
              case MySciNet.Redis.hgetalls(login_keys, &parse_login_val/2) do
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
end

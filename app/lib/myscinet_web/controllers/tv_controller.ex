defmodule MySciNetWeb.TvController do
  use MySciNetWeb, :controller
  alias MySciNetWeb.Clusters
  alias MySciNet.ClusterStats

  def index(conn, _params) do
    now_unix = DateTime.utc_now() |> DateTime.to_unix()

    vast =
      case ClusterStats.get_vast() do
        {:ok, v} -> v
        _ -> nil
      end

    case ClusterStats.get_clusters(Clusters.get_clusters()) do
      {:ok, clusters} ->
        conn
        |> assign(:clusters, clusters)
        |> assign(:vast, vast)
        |> assign(:now_unix, now_unix)
        |> render(:index)

      _ ->
        conn
        |> assign(:clusters, [])
        |> assign(:vast, vast)
        |> assign(:now_unix, now_unix)
        |> render(:index)
    end
  end
end

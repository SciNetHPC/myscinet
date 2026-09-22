defmodule MySciNetWeb.PageController do
  use MySciNetWeb, :controller
  alias MySciNetWeb.Clusters
  alias MySciNet.ClusterStats

  def home(conn, _params) do
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
        |> render(:home)

      _ ->
        conn
        |> assign(:clusters, [])
        |> assign(:vast, vast)
        |> put_flash(:error, "Failed to load clusters")
        |> render(:home)
    end
  end
end

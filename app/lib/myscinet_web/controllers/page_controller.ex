defmodule MySciNetWeb.PageController do
  use MySciNetWeb, :controller

  @clusters [
    %{
      slug: "trillium",
      name: "Trillium",
      nodes: 1224,
    },
    %{
      slug: "grillium",
      name: "Trillium GPU",
      nodes: 61,
    },
    %{
      slug: "balam",
      name: "Balam",
      nodes: 10,
    }
  ]

  defp string_to_float(s) do
    case Float.parse(s) do
      {f, _} -> f
      :error -> :erlang.nan()
    end
  end

  defp parse_val("nodesRunning", sval), do: string_to_float(sval)
  defp parse_val(_, sval), do: String.to_integer(sval)

  defp get_clusters(clusters) do
    cmds = for cluster <- clusters, do: ["HGETALL", "cluster:#{cluster[:slug]}"]
    case MySciNet.Redis.pipeline(cmds) do
      {:ok, raws} ->
        # convert ["a", "0", ...] -> %{a: 0, ...}
        results = for {cluster, raw} <- Enum.zip(clusters, raws), do:
          raw
          |> Enum.chunk_every(2)
          |> Enum.into(cluster, fn [k, v] -> {String.to_atom(k), parse_val(k,v)} end)
        {:ok, results}
      error ->
        error
    end
  end

  def home(conn, _params) do
    case get_clusters(@clusters) do
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

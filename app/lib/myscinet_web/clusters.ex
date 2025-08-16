defmodule MySciNetWeb.Clusters do
  @clusters [
    %{
      name: "Trillium",
      slug_web: "trillium",
      slug_redis: "trillium",
      slug_psql: "tric",
      nodes: 1224,
      cpumem: 768,
      gpu?: false,
      logins: [
        "tri-login01",
        "tri-login02",
        "tri-login03",
        "tri-login04",
        "tri-login05",
        "tri-login06"
      ]
    },
    %{
      name: "Trillium GPU",
      slug_web: "trillium-gpu",
      slug_redis: "grillium",
      slug_psql: "trig",
      nodes: 61,
      cpumem: 768,
      gpu?: true,
      logins: ["trig-login01"]
    },
    %{
      name: "Balam",
      slug_web: "balam",
      slug_redis: "balam",
      slug_psql: "balam",
      nodes: 10,
      cpumem: 1000,
      gpu?: true,
      logins: ["balam-login01"]
    }
  ]

  @slug_psql_to_web_map (for cluster <- @clusters, into: %{} do
                           {cluster.slug_psql, cluster.slug_web}
                         end)

  def get_clusters do
    @clusters
  end

  def get_cluster(slug) do
    Enum.find(@clusters, fn c ->
      c.slug_web == slug || c.slug_redis == slug || c.slug_psql == slug
    end)
  end

  def to_psql_jobid(cluster_slug, cluster_job_id) do
    cluster = get_cluster(cluster_slug)
    "#{cluster.slug_psql}:#{cluster_job_id}"
  end

  def from_psql_jobid(psql_jobid) do
    case String.split(psql_jobid, ":") do
      [slug_psql, cluster_job_id] -> {@slug_psql_to_web_map[slug_psql], cluster_job_id}
      _ -> nil
    end
  end
end

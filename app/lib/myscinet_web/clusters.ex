defmodule MySciNetWeb.Clusters do
  alias MySciNet.Hostlist

  # Each cluster's hardware is described by its `nodes`, a list of node types.
  # A node type's `hostlist` is a Slurm hostlist ("trig[0101-0152]") of the
  # nodes it covers.
  #
  # Per-node fields:
  #   billing  - billing units (cores or GPUs, see `gpu?`) per node
  #   cpumem   - host memory [GiB]
  #   gpumem   - memory per GPU [GiB]
  #   gpupower - power limit per GPU [W]
  #
  # The cluster-level `nnodes` and `billing` totals are computed from these.
  @cluster_defs [
    %{
      name: "Trillium",
      slug_web: "trillium",
      slug_redis: "trillium",
      slug_psql: "tric",
      gpu?: false,
      logins: [
        "tri-login01",
        "tri-login02",
        "tri-login03",
        "tri-login04",
        "tri-login05",
        "tri-login06"
      ],
      nodes: [
        %{
          hostlist: "tri[0001-1224,1225,1226,1237,1238,1249,1250,1261,1262,1273,1274]",
          billing: 1,
          cpumem: 755
        },
        # TODO: specs for the nept nodes
        %{hostlist: "nept[0002-0040]", billing: 1, cpumem: 768}
      ]
    },
    %{
      name: "Trillium GPU",
      slug_web: "trillium-gpu",
      slug_redis: "grillium",
      slug_psql: "trig",
      gpu?: true,
      logins: ["trig-login01"],
      nodes: [
        # H100
        %{hostlist: "trig[0001-0062]", billing: 4, cpumem: 755, gpumem: 80, gpupower: 750},
        # H200
        %{hostlist: "trig[0063]", billing: 4, cpumem: 1511, gpumem: 140, gpupower: 750},
        # B200
        %{hostlist: "trig[0101-0152]", billing: 8, cpumem: 2015, gpumem: 180, gpupower: 1000}
      ]
    },
    %{
      name: "Balam",
      slug_web: "balam",
      slug_redis: "balam",
      slug_psql: "balam",
      gpu?: true,
      logins: ["balam-login01"],
      nodes: [
        %{hostlist: "balam[001-010]", billing: 4, cpumem: 1000, gpumem: 40, gpupower: 400}
      ]
    }
  ]

  @clusters (for cluster <- @cluster_defs do
               nodes =
                 for type <- cluster.nodes do
                   hosts = Hostlist.expand(type.hostlist)
                   Map.merge(type, %{hosts: MapSet.new(hosts), count: length(hosts)})
                 end

               Map.merge(cluster, %{
                 nodes: nodes,
                 nnodes: nodes |> Enum.map(& &1.count) |> Enum.sum(),
                 billing: nodes |> Enum.map(&(&1.count * &1.billing)) |> Enum.sum()
               })
             end)

  @slug_psql_to_web_map (for cluster <- @clusters, into: %{} do
                           {cluster.slug_psql, cluster.slug_web}
                         end)

  @spec_keys [:cpumem, :gpumem, :gpupower]

  def get_clusters do
    @clusters
  end

  def total_jobs(cluster) do
    Map.get(cluster, :active_count, 0) + Map.get(cluster, :queued_count, 0)
  end

  def days_of_work(cluster) do
    (Map.get(cluster, :active_procsecs, 0) + Map.get(cluster, :queued_procsecs, 0)) /
      (86400.0 * cluster.billing)
  end

  @doc """
  The node type of `cluster` that `nodename` belongs to, or nil.
  """
  def node_type(cluster, nodename) do
    Enum.find(cluster.nodes, &MapSet.member?(&1.hosts, nodename))
  end

  @doc """
  Hardware specs (cpumem/gpumem/gpupower) for a job running on `nodelist`
  (a Slurm hostlist string). For jobs spanning several node types, takes the
  max of each spec; if no node matches (e.g. a pending job), takes the max
  over all of the cluster's node types. Missing specs (e.g. gpumem on a CPU
  cluster) are 0.
  """
  def node_specs(cluster, nodelist) do
    types =
      nodelist
      |> Hostlist.expand()
      |> Enum.map(&node_type(cluster, &1))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    types = if types == [], do: cluster.nodes, else: types

    for key <- @spec_keys, into: %{} do
      {key, types |> Enum.map(&Map.get(&1, key, 0)) |> Enum.max()}
    end
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

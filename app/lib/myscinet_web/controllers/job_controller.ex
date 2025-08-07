defmodule MySciNetWeb.JobController do
  use MySciNetWeb, :controller

  alias MySciNet.Repo
  alias MySciNet.Jsum
  import Ecto.Query
  import MySciNetWeb.Permissions

  @page_size 20

  defp query_authz(query, conn) do
    username = conn.assigns.current_user.username
    groups = conn.assigns.current_user.groups
    cond do
      is_staff_user?(conn) ->
        # staff can see all jobs
        query
      "def-#{username}" in groups ->
        # PIs can see their group's jobs
        query
        |> where([j], like(j.groupname, ^"%-#{username}"))
        |> where([j], like(j.groupname, ^"%-#{username}-%"))
      true ->
        # everyone else can only see their own jobs
        query |> where(username: ^username)
    end
  end

  def index(conn, params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    offset = (page - 1) * @page_size

    jobsq =
      Jsum
      |> query_authz(conn)
      |> where([j], not ilike(j.partition, ^"debug%"))
      |> order_by([j], desc: j.submit)
      |> limit(^@page_size)
      |> offset(^offset)

    filters =
      Map.get(params, "q", "")
      |> String.trim()
      |> MySciNet.JobQuery.parse()

    {conn, jobsq} =
      case filters do
        {:ok, ast} -> {conn, jobsq |> apply_filters(ast)}
        _ -> {conn |> put_flash(:error, "Invalid query"), jobsq}
      end

    jobs = jobsq |> Repo.all()

    render(conn, "index.html", page_title: "jobs",
      jobs: jobs,
      page: page
    )
  end

  defp apply_filters(query, []), do: query
  defp apply_filters(query, [filter | rest]) do
    query |> apply_filter(filter) |> apply_filters(rest)
  end

  defp apply_filter(query, filter) do
    case filter do
      {:is_eq, :cluster, cluster} ->
        query |> where([j], ilike(j.jobid, ^"#{cluster_slug(cluster)}:%"))
      {:is_eq, :user, u} -> query |> where(username: ^to_string(u))
      {:is_eq, :group, g} -> query |> where(groupname: ^to_string(g))
      {:is_eq, :nodes, n} -> query |> where(nnodes: ^n)
      {:is_lt, :nodes, n} -> query |> where([j], j.nnodes < ^n)
      {:is_le, :nodes, n} -> query |> where([j], j.nnodes <= ^n)
      {:is_gt, :nodes, n} -> query |> where([j], j.nnodes > ^n)
      {:is_ge, :nodes, n} -> query |> where([j], j.nnodes >= ^n)
      _ -> query
    end
  end

  defp cluster_slug(name) do
    case to_string(name) do
      "trillium" -> "tric"
      "grillium" -> "trig"
      "trillium-gpu" -> "trig"
      other -> other
    end
  end

  defp join_jobid(cluster, id) do
    "#{cluster_slug(cluster)}:#{id}"
  end

  defp is_gpu_cluster?(cluster) do
    cluster in ["balam", "grillium", "trillium-gpu", "trig"]
  end

  def show(conn, %{"cluster" => cluster, "id" => cid}) do
    id = join_jobid(cluster, cid)
    job =
      Jsum
      |> query_authz(conn)
      |> where(jobid: ^id)
      |> Repo.one()

    case job do
      nil ->
        conn
        |> put_status(:not_found)
        |> text("not found or not permitted")
      _ ->
        row = Repo.get_by(MySciNet.Jscript, jobid: id)
        script = row && row.jobscript

        row = Repo.get_by(MySciNet.Jcom, jobid: id)
        command =
          case row && row.jobcom do
            nil -> nil
            str -> String.replace(str, "/opt/slurm/bin/sbatch --export=NONE", "sbatch")
          end

        row = Repo.get_by(MySciNet.Jenv, jobid: id)
        env = row && row.jobenv

        render(conn, "show.html", page_title: "job #{id}",
          command: command,
          job: job,
          env: env,
          script: script
        )
    end
  end

  def perf(conn, %{"cluster" => cluster, "id" => cid}) do
    id = join_jobid(cluster, cid)

    {table, cols} = if is_gpu_cluster?(cluster) do
      {:utilgpu, [
        :nodename,
        :gpu,
        :cpupercent,
        :memfree,
        :buffers,
        :cached,
        :dcgm_fi_prof_gr_engine_active,
        :dcgm_fi_prof_pipe_fp16_active,
        :dcgm_fi_prof_pipe_fp32_active,
        :dcgm_fi_prof_pipe_fp64_active,
        :dcgm_fi_prof_pipe_tensor_active,
        :dcgm_fi_prof_sm_active,
        :dcgm_fi_prof_sm_occupancy,
      ]}
    else
      {:utilcpu, [
        :nodename,
        :memfree,
        :buffers,
        :cached,
        :cpupercent,
        :iowait,
        :loadavg,
        :cput1,
        :cput2,
        :acores,
        :instruct,
        :clicks,
        :freq,
        :cpi,
        :temp,
        :power,
        :powerdram,
        :mflops,
        :memread,
        :memwrite,
        :smflops,
        :portxmitdata,
        :portrcvdata,
        :portxmitpkts,
        :portrcvpkts
      ]}
    end

    cols = Enum.join(Enum.map(cols, &Atom.to_string/1), ",")
    escaped_id = String.replace(id, "'", "''")
    query = "COPY (SELECT to_char(time,'YYYY-MM-DD\"T\"HH24:MI:SS') as time,#{cols} FROM #{table} WHERE jobid = '#{escaped_id}' ORDER BY time) TO STDOUT CSV HEADER"

    conn = conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("cache-control", "max-age=120, private")
    |> send_chunked(:ok)

    Repo.transaction fn ->
      Ecto.Adapters.SQL.stream(MySciNet.Repo, query)
      |> Stream.map(&(chunk(conn, &1.rows)))
      |> Stream.run
    end

    conn
  end
end

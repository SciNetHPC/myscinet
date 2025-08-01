defmodule MySciNetWeb.JobController do
  use MySciNetWeb, :controller

  alias MySciNet.Repo
  alias MySciNet.Jsum
  import Ecto.Query

  @page_size 20

  def index(conn, params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    offset = (page - 1) * @page_size

    jobs =
      Jsum
      |> where([j], not ilike(j.partition, ^"debug%"))
      |> order_by([j], desc: j.submit)
      |> limit(^@page_size)
      |> offset(^offset)
      |> Repo.all()

    render(conn, "index.html", page_title: "jobs",
      jobs: jobs,
      page: page
    )
  end

  defp cluster_slug(name) do
    case name do
      "trillium" -> "tric"
      "grillium" -> "trig"
      "trillium-gpu" -> "trig"
      _ -> name
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
    job = Repo.get_by(Jsum, jobid: id)
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

defmodule MySciNetWeb.JobController do
  use MySciNetWeb, :controller

  alias MySciNet.Repo
  alias MySciNet.Tgjsum
  import Ecto.Query

  @page_size 20

  def index(conn, params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    offset = (page - 1) * @page_size

    jobs =
      Tgjsum
      |> where([j], not ilike(j.partition, ^"debug%"))
      |> order_by([j], desc: j.submit)
      |> limit(^@page_size)
      |> offset(^offset)
      |> Repo.all()

    render(conn, "index.html", jobs: jobs, page: page)
  end

  def show(conn, %{"cluster" => cluster, "id" => cid}) do
    id = "#{cid}" # XXX:TBD temporary fallback
    job = Repo.get_by!(Tgjsum, jobid: id)
    script = Repo.get_by(MySciNet.Tgjscript, jobid: id)
    command_row = Repo.get_by(MySciNet.Tgjcom, jobid: id)
    command =
      case command_row && command_row.jobcom do
        nil -> nil
        str -> String.replace(str, "/opt/slurm/bin/sbatch --export=NONE", "sbatch")
      end
    env_row = Repo.get_by(MySciNet.Tgjenv, jobid: id)
    jobenv = env_row && env_row.jobenv

    render(conn, "show.html",
      command: command,
      job: job,
      jobenv: jobenv,
      jobscript: script && script.jobscript
    )
  end

  def perf(conn, %{"cluster" => cluster, "id" => id}) do
    cols = [
      :time,
      :nodename,
      :cpupercent,
      :dcgm_fi_prof_gr_engine_active,
      :dcgm_fi_prof_pipe_fp64_active
    ]

    util_data =
      MySciNet.Tgutil
      |> where([u], u.jobid == ^id)
      |> select([u], ^cols)
      |> order_by([u], u.time)
      |> Repo.all()

    rows = for row <- util_data do
      for col <- cols do
        v = Map.get(row, col)
        if col == :time do
          NaiveDateTime.to_iso8601(v)
        else
          v
        end
      end
    end

    csv =
      CSV.encode([cols|rows], delimiter: "\n")
      |> Enum.join("")

    conn
    |> put_resp_content_type("text/tab-separated-values")
    |> put_resp_header("cache-control", "max-age=120, private")
    |> send_resp(200, csv)
  end
end

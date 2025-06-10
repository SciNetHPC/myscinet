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
      |> order_by([j], desc: j.submit)
      |> limit(^@page_size)
      |> offset(^offset)
      |> Repo.all()

    render(conn, "index.html", jobs: jobs, page: page)
  end

  def show(conn, %{"id" => id}) do
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
    render(conn, "show.html", job: job, jobscript: script && script.jobscript, command: command, jobenv: jobenv)
  end
end

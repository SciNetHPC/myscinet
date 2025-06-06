defmodule MySciNetWeb.JobController do
  use MySciNetWeb, :controller

  alias MySciNet.Repo
  alias MySciNet.Tcjsum
  import Ecto.Query

  @page_size 20

  def index(conn, params) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    offset = (page - 1) * @page_size

    jobs =
      Tcjsum
      |> order_by([j], desc: j.submit)
      |> limit(^@page_size)
      |> offset(^offset)
      |> Repo.all()

    render(conn, "index.html", jobs: jobs, page: page)
  end

  def show(conn, %{"id" => id}) do
    job = Repo.get_by!(Tcjsum, jobid: id)
    render(conn, "show.html", job: job)
  end
end

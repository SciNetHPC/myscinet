defmodule MySciNetWeb.UserController do
  use MySciNetWeb, :controller

  def index(conn, %{"q" => q}) do
    case MySciNet.LDAP.user_search(q) do
      {:ok, users} ->
        render(conn, :index, page_title: "users #{q}", users: users)

      error ->
        dbg(error)

        conn
        |> put_flash(:error, "LDAP search error")
        |> render(:index, users: [])
    end
  end

  def index(conn, _), do: render(conn, :index, page_title: "users")

  def show(conn, %{"id" => id}) do
    case MySciNet.LDAP.user_info(id) do
      {:ok, info} ->
        render(conn, :show, page_title: "user #{info.username}", user: info)

      error ->
        dbg(error)

        conn
        |> put_flash(:error, "User not found")
        |> redirect(to: ~p"/users")
    end
  end

  def naughty(conn, _) do
    query =
      """
      select
        username,
        sum(samples)::integer as total_samples,
        sum(samples*percent_wasted)/sum(samples) as wasted_percent,
        sum(samples*percent_wasted)/sqrt(sum(samples)) as demerits
      from (
        select
          jobid,
          count(*) as samples,
          1.0 - greatest(avg(cpupercent)/100.0, 1.0 - min(memfree + buffers + cached)/(500*1024.0)) as percent_wasted
        from utilcpu
        where time > now() - interval '7 days'
        group by jobid
      ) jutilcpu
      join jsum on jutilcpu.jobid = jsum.jobid
      group by username
      having
        sum(samples*percent_wasted) > 7*24*30
      order by demerits desc
      limit 10;
      """

    results = Ecto.Adapters.SQL.query!(MySciNet.Repo, query, [])
    render(conn, :naughty, page_title: "Naughty Users", naughty_list: results)
  end
end

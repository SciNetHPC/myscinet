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
    a_week_ago = DateTime.utc_now() |> DateTime.add(-7, :day)
    query =
      """
      select username, count(*), avg(wastage) as wastage, avg(wastage)*sqrt(count(*)) as demerits
      from (
        select jobid, time,
          (100 - greatest(cpupercent, 100*(1 - (memfree+buffers+cached)/393216))) as wastage
        from utilcpu
      ) utilcpu2
      join jsum on utilcpu2.jobid = jsum.jobid
      where time > $1
      group by username
      order by demerits desc
      limit 10;
      """
    results = Ecto.Adapters.SQL.query!(MySciNet.Repo, query, [a_week_ago])
    render(conn, :naughty, page_title: "Naughty Users", naughty_list: results)
  end
end

defmodule MySciNetWeb.UserController do
  use MySciNetWeb, :controller

  def index(conn, %{"q" => q}) do
    users = MySciNet.LDAP.user_search(q)
    render(conn, :index, users: users)
  end
  def index(conn, _), do: render(conn, :index)

  def show(conn, %{"id" => id}) do
    redirect(conn, to: ~p"/jobs?q=user:#{id}")
  end
end

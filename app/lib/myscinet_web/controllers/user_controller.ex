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
end

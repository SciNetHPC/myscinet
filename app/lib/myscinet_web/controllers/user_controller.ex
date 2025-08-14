defmodule MySciNetWeb.UserController do
  use MySciNetWeb, :controller

  def index(conn, %{"q" => q}) do
    case MySciNet.LDAP.user_search(q) do
      {:ok, users} ->
        render(conn, :index, users: users)

      error ->
        dbg(error)

        conn
        |> put_flash(:error, "LDAP search error")
        |> render(:index, users: [])
    end
  end

  def index(conn, _), do: render(conn, :index)

  def show(conn, %{"id" => id}) do
    case MySciNet.LDAP.user_info(id) do
      {:ok, info} ->
        render(conn, :show, user: info)

      error ->
        dbg(error)

        conn
        |> put_flash(:error, "User not found")
        |> redirect(to: "/users")
    end
  end
end

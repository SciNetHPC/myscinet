defmodule MySciNetWeb.LoginController do
  use MySciNetWeb, :controller

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"username" => username, "password" => password}) do
    case MySciNet.LDAP.authenticate(username, password) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("Login successful!"))
        |> put_session(:user, username)
        |> redirect(to: "/")
      _ ->
        conn
        |> put_flash(:error, gettext("Invalid username or password."))
        |> render(:new)
    end
  end
end

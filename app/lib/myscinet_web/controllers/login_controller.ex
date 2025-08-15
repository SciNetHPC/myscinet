defmodule MySciNetWeb.LoginController do
  use MySciNetWeb, :controller

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"username" => username, "password" => password}) do
    case MySciNet.LDAP.authenticate(username, password) do
      {:ok, info} ->
        redirect_to = get_session(conn, :redirect_to) || ~p"/"
        conn
        |> put_flash(:info, gettext("Login successful!"))
        |> delete_session(:redirect_to)
        |> put_session(:current_user, info)
        |> redirect(to: redirect_to)
      _ ->
        :timer.sleep(1000) # Slow down brute force attacks
        conn
        |> put_flash(:error, gettext("Invalid username or password."))
        |> render(:new)
    end
  end

  def delete(conn, _params) do
    current_user = conn.assigns.current_user
    conn
    |> clear_session
    |> put_flash(:info, gettext("Signed out %{user}", user: current_user.username))
    |> redirect(to: ~p"/")
  end
end

defmodule MySciNetWeb.PageController do
  use MySciNetWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

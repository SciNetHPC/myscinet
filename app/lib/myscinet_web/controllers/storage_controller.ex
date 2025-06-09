defmodule MySciNetWeb.StorageController do
  use MySciNetWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end

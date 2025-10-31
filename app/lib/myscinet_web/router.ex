defmodule MySciNetWeb.Router do
  use MySciNetWeb, :router

  defp assign_if_in_session(conn, key) do
    if conn.assigns[key] do
      conn
    else
      val = get_session(conn, key)

      if val do
        assign(conn, key, val)
      else
        conn
      end
    end
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug MySciNetWeb.Plugs.SetLocale
    plug :fetch_live_flash
    plug :put_root_layout, html: {MySciNetWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :assign_if_in_session, :current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  defp authenticate(conn, _) do
    if conn.assigns[:current_user] do
      conn
    else
      full_path =
        %URI{path: conn.request_path, query: conn.query_string}
        |> URI.to_string()

      conn
      |> put_session(:redirect_to, full_path)
      |> redirect(to: "/login")
      |> halt
    end
  end

  defp is_staff_user(conn, _) do
    if MySciNetWeb.Permissions.is_staff_user?(conn) do
      conn
    else
      conn
      |> put_status(404)
      |> halt
    end
  end

  defp is_superuser(conn, _) do
    if MySciNetWeb.Permissions.is_superuser?(conn) do
      conn
    else
      conn
      |> put_status(404)
      |> halt
    end
  end

  pipeline :authenticated do
    plug :authenticate
  end

  pipeline :staff do
    plug :is_staff_user
  end

  pipeline :superuser do
    plug :is_superuser
  end

  scope "/", MySciNetWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/login", LoginController, :new
    post "/login", LoginController, :create
  end

  scope "/", MySciNetWeb do
    pipe_through [:browser, :authenticated]

    get "/allocations", AllocationController, :index
    get "/allocations/:cluster/:id", AllocationController, :show
    get "/jobs", JobController, :index
    get "/jobs/:cluster/:id", JobController, :show
    get "/jobs/:cluster/:id/perf.csv", JobController, :perf
    post "/logout", LoginController, :delete
    get "/storage", StorageController, :index
  end

  scope "/", MySciNetWeb do
    pipe_through [:browser, :authenticated, :staff]

    get "/users", UserController, :index
    get "/users/:id", UserController, :show
    get "/users/:id/allocations", AllocationController, :user_allocations
    get "/users/:id/storage", StorageController, :user_storage
  end

  scope "/", MySciNetWeb do
    pipe_through [:browser, :authenticated, :staff, :superuser]

    get "/naughty-list", UserController, :naughty
  end

  # Other scopes may use custom stacks.
  # scope "/api", MySciNetWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:myscinet, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MySciNetWeb.Telemetry
    end
  end
end

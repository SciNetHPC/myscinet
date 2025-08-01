defmodule MySciNetWeb.Router do
  use MySciNetWeb, :router

  pipeline :browser do
    plug MySciNetWeb.Plugs.SetLocale
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MySciNetWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MySciNetWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/allocations", AllocationsController, :index
    get "/storage", StorageController, :index
  end

  scope "/jobs", MySciNetWeb do
    pipe_through :browser

    get "/", JobController, :index
    get "/:cluster/:id", JobController, :show
    get "/:cluster/:id/perf.csv", JobController, :perf
  end

  scope "/login", MySciNetWeb do
    pipe_through :browser

    get "/", LoginController, :new
    post "/", LoginController, :create
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

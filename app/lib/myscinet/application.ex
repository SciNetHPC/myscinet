defmodule MySciNet.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MySciNetWeb.Telemetry,
      MySciNet.Redis,
      MySciNet.Repo,
      {Cachex, name: :myscinet_cache},
      {DNSCluster, query: Application.get_env(:myscinet, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MySciNet.PubSub},
      # Start a worker by calling: MySciNet.Worker.start_link(arg)
      # {MySciNet.Worker, arg},
      # Start to serve requests, typically the last entry
      MySciNetWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MySciNet.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MySciNetWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

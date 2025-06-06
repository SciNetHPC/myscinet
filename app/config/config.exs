# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :myscinet,
  namespace: MySciNet,
  ecto_repos: [MySciNet.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :myscinet, MySciNetWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MySciNetWeb.ErrorHTML, json: MySciNetWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MySciNet.PubSub,
  live_view: [signing_salt: "9F9X1kDa"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  myscinet: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.0.9",
  myscinet: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Gettext
config :myscinet, MySciNetWeb.Gettext,
  locales: ~w(en fr),
  default_locale: "fr"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

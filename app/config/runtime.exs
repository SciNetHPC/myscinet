import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/myscinet start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :myscinet, MySciNetWeb.Endpoint, server: true
end

# The secret key base is used to sign/encrypt cookies and other secrets.
config :myscinet, MySciNetWeb.Endpoint, secret_key_base: System.get_env("SECRET_KEY_BASE")

maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

config :myscinet, MySciNet.Repo,
  url: System.get_env("DATABASE_URL"),
  socket_options: maybe_ipv6

config :myscinet, MySciNet.LDAP,
  hosts: System.get_env("LDAP_HOSTS"),
  port: String.to_integer(System.get_env("LDAP_PORT") || "636"),
  bind_dn: System.get_env("LDAP_BIND_DN"),
  bind_pw: System.get_env("LDAP_BIND_PW"),
  user_base: System.get_env("LDAP_USER_BASE") || "ou=users,dc=scinet,dc=utoronto,dc=ca",
  group_base: System.get_env("LDAP_GROUP_BASE") || "ou=groups,dc=scinet,dc=utoronto,dc=ca"

if config_env() == :prod do
  host = System.get_env("PHX_HOST") || "my.scinet.utoronto.ca"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :myscinet, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :myscinet, MySciNetWeb.Endpoint,
    url: [host: host],
    http: [
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0},
      port: port,
      compress: true
    ]

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :myscinet, MySciNetWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :myscinet, MySciNetWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end

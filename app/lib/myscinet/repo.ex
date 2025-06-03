defmodule MySciNet.Repo do
  use Ecto.Repo,
    otp_app: :myscinet,
    adapter: Ecto.Adapters.Postgres
end

defmodule MySciNet.Tcjenv do
  use Ecto.Schema

  @primary_key false
  schema "tcjenv" do
    field :jobid, :string
    field :jobenv, :string
  end
end

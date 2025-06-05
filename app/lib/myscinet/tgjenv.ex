defmodule MySciNet.Tgjenv do
  use Ecto.Schema

  @primary_key false
  schema "tgjenv" do
    field :jobid, :string
    field :jobenv, :string
  end
end

defmodule MySciNet.Jenv do
  use Ecto.Schema

  @primary_key false
  schema "jenv" do
    field :jobid, :string
    field :jobenv, :string
  end
end

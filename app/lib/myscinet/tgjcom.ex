defmodule MySciNet.Tgjcom do
  use Ecto.Schema

  @primary_key false
  schema "tgjcom" do
    field :jobid, :string
    field :jobcom, :string
  end
end

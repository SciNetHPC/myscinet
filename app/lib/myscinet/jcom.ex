defmodule MySciNet.Jcom do
  use Ecto.Schema

  @primary_key false
  schema "jcom" do
    field :jobid, :string
    field :jobcom, :string
  end
end

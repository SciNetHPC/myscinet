defmodule MySciNet.Tgjscript do
  use Ecto.Schema

  @primary_key false
  schema "tgjscript" do
    field :jobid, :string
    field :jobscript, :string
  end
end

defmodule MySciNet.Tcjscript do
  use Ecto.Schema

  @primary_key false
  schema "tcjscript" do
    field :jobid, :string
    field :jobscript, :string
  end
end

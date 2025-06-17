defmodule MySciNet.Jscript do
  use Ecto.Schema

  @primary_key false
  schema "jscript" do
    field :jobid, :string
    field :jobscript, :string
  end
end

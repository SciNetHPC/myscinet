defmodule MySciNet.Tcjcom do
  use Ecto.Schema

  @primary_key false
  schema "tcjcom" do
    field :jobid, :string
    field :jobcom, :string
  end
end

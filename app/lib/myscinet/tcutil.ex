defmodule MySciNet.Tcutil do
  use Ecto.Schema

  @primary_key false
  schema "tcutil" do
    field :nodename, :string
    field :time, :naive_datetime
    field :jobid, :string
    field :memfree, :integer
    field :buffers, :integer
    field :cached, :integer
    field :cpupercent, :float
    field :iowait, :integer
    field :loadavg, :float
    field :cput1, :integer
    field :cput2, :integer
    field :acores, :integer
    field :instruct, :float
    field :clicks, :float
    field :freq, :float
    field :cpi, :float
    field :temp, :float
    field :power, :float
    field :powerdram, :float
    field :mflops, :float
    field :memread, :float
    field :memwrite, :float
    field :smflops, :float
    field :portxmitdata, :integer
    field :portrcvdata, :integer
    field :portxmitpkts, :integer
    field :portrcvpkts, :integer
  end
end

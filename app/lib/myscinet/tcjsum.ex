defmodule MySciNet.Tcjsum do
  use Ecto.Schema

  @primary_key false
  schema "tcjsum" do
    field :account, :string
    field :alloctres, :string
    field :cputime, :string
    field :elapsed, :string
    field :eligible, :naive_datetime
    field :endtime, :string
    field :exitcode, :string
    field :gid, :integer
    field :groupname, :string
    field :jobid, :string
    field :jobname, :string
    field :maxdiskread, :string
    field :maxdiskwrite, :string
    field :maxrss, :string
    field :maxvmsize, :string
    field :nnodes, :integer
    field :nodelist, :string
    field :priority, :integer
    field :partition, :string
    field :qos, :string
    field :start, :naive_datetime
    field :state, :string
    field :submit, :naive_datetime
    field :systemcpu, :string
    field :timelimit, :string
    field :totalcpu, :string
    field :uid, :integer
    field :username, :string
    field :usercpu, :string
    field :workdir, :string
  end
end

defmodule MySciNet.Redis do
  @moduledoc """
  Simple Redis client wrapper for retrieving data from a Redis server.
  """

  def child_spec(opts \\ []) do
    config = Application.get_env(:myscinet, __MODULE__)
    Redix.child_spec({config[:url], [name: __MODULE__, password: config[:password]] ++ opts})
  end

  def pipeline(commands) do
    Redix.pipeline(__MODULE__, commands)
  end

end

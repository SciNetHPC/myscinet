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

  defp hgetall_result_to_map(raw, parse_val) do
    raw
    |> Enum.chunk_every(2)
    |> Enum.into(%{}, fn [k, v] -> {String.to_atom(k), parse_val.(k, v)} end)
  end

  def hgetalls(keys, parse_val) do
    cmds = for key <- keys, do: ["HGETALL", key]

    case pipeline(cmds) do
      {:ok, results} ->
        if Enum.any?(results, &(&1 == [])) do
          {:error, :not_found}
        else
          {:ok, Enum.map(results, &hgetall_result_to_map(&1, parse_val))}
        end

      error ->
        error
    end
  end
end

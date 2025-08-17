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
        case Enum.find_index(results, &(&1 == [])) do
          nil ->
            {:ok, Enum.map(results, &hgetall_result_to_map(&1, parse_val))}

          idx ->
            key = Enum.at(keys, idx)
            {:error, {:not_found, key}}
        end

      error ->
        error
    end
  end
end

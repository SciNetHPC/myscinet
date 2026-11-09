defmodule MySciNet.Hostlist do
  @moduledoc """
  Slurm hostlist expressions, e.g. "trig[0062-0063,0101],trig0150".
  """

  @doc """
  Expands a Slurm hostlist, e.g. "trig[0062-0063,0101],trig0150" ->
  ["trig0062", "trig0063", "trig0101", "trig0150"].
  """
  def expand(nil), do: []

  def expand(hostlist) do
    Regex.scan(~r/([^,\[]+)(?:\[([^\]]*)\])?/, hostlist)
    |> Enum.flat_map(fn
      [_, host] ->
        [host]

      [_, prefix, ranges] ->
        ranges
        |> String.split(",")
        |> Enum.flat_map(fn range ->
          case String.split(range, "-") do
            [lo, hi] ->
              for i <- String.to_integer(lo)..String.to_integer(hi) do
                prefix <> String.pad_leading(Integer.to_string(i), String.length(lo), "0")
              end

            [id] ->
              [prefix <> id]
          end
        end)
    end)
  end
end

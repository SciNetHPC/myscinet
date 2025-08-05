defmodule MySciNet.JobQuery do
  @moduledoc """
  Wrapper for the Lucene-like query parser (fields: cluster, nodes).
  """

  @doc """
  Parse a query string into an AST.
  Returns {:ok, ast} or {:error, reason}.
  """
  def parse(""), do: {:ok, []}
  def parse(str) when is_binary(str) do
    case :query_lexer.string(String.to_charlist(str)) do
      {:ok, tokens, _} -> :query_parser.parse(tokens)
      {:error, err, _} -> {:error, err}
    end
  end
end

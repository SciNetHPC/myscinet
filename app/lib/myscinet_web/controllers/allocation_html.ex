defmodule MySciNetWeb.AllocationHTML do
  use MySciNetWeb, :html
  embed_templates "allocation_html/*"

  def nice_round_cores(x) do
    case x do
      x when x >= 100 -> round(x)
      x when x >= 10 -> Float.round(x, 1)
      _ -> Float.round(x, 2)
    end
  end
end

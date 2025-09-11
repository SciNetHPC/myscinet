defmodule MySciNetWeb.StorageHTML do
  use MySciNetWeb, :html
  embed_templates "storage_html/*"

  @doc "Convert bytes to a human-readable string."
  def human_bytes(b) when is_integer(b) and b > 0 do
    # Gettext macro expects message keys to expand to strings at compile-time
    cond do
      b >= 1024 * 1024 * 1024 * 1024 ->
        threshold = 1024 * 1024 * 1024 * 1024
        gettext("%{val} TiB", val: Float.round(b / threshold, 2))

      b >= 1024 * 1024 * 1024 ->
        threshold = 1024 * 1024 * 1024
        gettext("%{val} GiB", val: Float.round(b / threshold, 2))

      b >= 1024 * 1024 ->
        threshold = 1024 * 1024
        gettext("%{val} MiB", val: Float.round(b / threshold, 2))

      b >= 1024 ->
        threshold = 1024
        gettext("%{val} KiB", val: Float.round(b / threshold, 2))

      true ->
        gettext("%{val} B", val: b)
    end
  end

  def human_bytes(0), do: gettext("0 B")

  @doc "Format inode counts with K/M/G suffixes for readability."
  def human_inodes(n) when is_integer(n) and n > 0 do
    units = [{1_000_000_000, "G"}, {1_000_000, "M"}, {1_000, "K"}]

    case Enum.find(units, fn {threshold, _} -> n >= threshold end) do
      {threshold, unit} -> "#{Float.round(n / threshold, 2)}#{unit}"
      nil -> "#{n}"
    end
  end

  def human_inodes(0), do: "0"

  @doc "Return a tailwind/daisyUI background class for a filled bar based on percent."
  def fill_class(percent) when is_number(percent) do
    cond do
      percent >= 90 -> "bg-error"
      percent >= 70 -> "bg-warning"
      true -> "bg-primary"
    end
  end

  @doc "Return the matching content text class for a filled bar (theme-safe)."
  def fill_text_class(percent) when is_number(percent) do
    cond do
      percent >= 90 -> "text-error-content"
      percent >= 70 -> "text-warning-content"
      true -> "text-primary-content"
    end
  end

  @doc "Format a value according to type (:bytes or :inodes)."
  def format_val(v, :bytes), do: human_bytes(v)
  def format_val(v, :inodes), do: human_inodes(v)
  def format_val(v, _), do: to_string(v)

  @doc "Function component rendering a usage bar + label.
  Accepts assigns: :percent, :used, :max, :format (:bytes|:inodes)"
  def usagebar(assigns) do
    assigns =
      assigns
      |> Phoenix.Component.assign_new(:percent, fn -> 0 end)
      |> Phoenix.Component.assign_new(:used, fn -> 0 end)
      |> Phoenix.Component.assign_new(:max, fn -> 0 end)
      |> Phoenix.Component.assign_new(:format, fn -> :bytes end)

    ~H"""
    <div>
      <div aria-hidden="true" class="w-full bg-base-200 rounded h-6 overflow-hidden relative">
        <div
          class={"absolute left-0 top-0 h-6 flex items-center justify-center text-sm font-semibold " <> fill_text_class(@percent) <> " " <> fill_class(@percent)}
          style={"width: #{min(@percent, 100)}%;"}
        >
          <%= if @percent >= 15 do %>
            <span class="px-1">{@percent}%</span>
          <% end %>
        </div>
      </div>

      <div class="text-xs text-base-content/50 mb-1">
        {gettext("Used %{used} out of %{max}",
          used: format_val(@used, @format),
          max: format_val(@max, @format)
        )}
      </div>
    </div>
    """
  end

  def display_path(<<"/trillium_", rest::binary>>), do: "/" <> rest
  def display_path(path) when is_binary(path), do: path
end

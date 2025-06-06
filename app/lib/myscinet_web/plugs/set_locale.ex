defmodule MySciNetWeb.Plugs.SetLocale do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    accept_language = get_req_header(conn, "accept-language") |> List.first() || "en"
    available_locales = Gettext.known_locales(MySciNetWeb.Gettext)
    locale =
      accept_language
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.slice(&1, 0, 2))
      |> Enum.find(fn lang -> lang in available_locales end) || "en"

    IO.puts("Setting locale to: #{locale}")
    Gettext.put_locale(locale)
    conn
  end
end

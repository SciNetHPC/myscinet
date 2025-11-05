defmodule MySciNetWeb.Plugs.SetLocale do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    default_locale = Application.get_env(:myscinet, MySciNetWeb.Gettext)[:default_locale] || "en"
    accept_language = get_req_header(conn, "accept-language") |> List.first() || default_locale
    available_locales = Gettext.known_locales(MySciNetWeb.Gettext)

    # Preference: ?locale= query param -> session -> Accept-Language -> default
    q_locale = conn.params["locale"]
    s_locale = get_session(conn, :locale)

    locale =
      cond do
        q_locale in available_locales ->
          q_locale

        s_locale in available_locales ->
          s_locale

        true ->
          accept_language
          |> String.split(",")
          |> Enum.map(&String.trim/1)
          |> Enum.map(&String.slice(&1, 0, 2))
          |> Enum.find(fn lang -> lang in available_locales end) || default_locale
      end

    Gettext.put_locale(locale)

    conn
    |> put_session(:locale, locale)
  end
end

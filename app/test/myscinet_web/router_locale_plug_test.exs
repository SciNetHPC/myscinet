defmodule MySciNetWeb.RouterLocalePlugTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  defp call_browser_pipeline(conn) do
    # Simulate the browser pipeline with the set_locale_from_accept_language plug
    MySciNetWeb.Router.set_locale_from_accept_language(conn, [])
  end

  test "sets locale to en when Accept-Language is en" do
    _conn = conn(:get, "/") |> put_req_header("accept-language", "en") |> call_browser_pipeline()
    assert Gettext.get_locale(MySciNetWeb.Gettext) == "en"
  end

  test "sets locale to fr when Accept-Language is fr" do
    _conn = conn(:get, "/") |> put_req_header("accept-language", "fr") |> call_browser_pipeline()
    assert Gettext.get_locale(MySciNetWeb.Gettext) == "fr"
  end

  test "sets locale to fr when Accept-Language is fr-CA" do
    _conn = conn(:get, "/") |> put_req_header("accept-language", "fr-CA") |> call_browser_pipeline()
    assert Gettext.get_locale(MySciNetWeb.Gettext) == "fr"
  end

  test "sets locale to fr when Accept-Language is fr-CA,fr;q=0.9,en;q=0.8" do
    _conn = conn(:get, "/") |> put_req_header("accept-language", "fr-CA,fr;q=0.9,en;q=0.8") |> call_browser_pipeline()
    assert Gettext.get_locale(MySciNetWeb.Gettext) == "fr"
  end

  test "defaults to en when Accept-Language is not set" do
    _conn = conn(:get, "/") |> call_browser_pipeline()
    assert Gettext.get_locale(MySciNetWeb.Gettext) == "en"
  end

  test "defaults to en when Accept-Language is not supported" do
    _conn = conn(:get, "/") |> put_req_header("accept-language", "es") |> call_browser_pipeline()
    assert Gettext.get_locale(MySciNetWeb.Gettext) == "en"
  end
end

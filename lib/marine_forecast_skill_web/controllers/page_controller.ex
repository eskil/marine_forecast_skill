defmodule MarineForecastSkillWeb.PageController do
  use MarineForecastSkillWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def privacy(conn, _params) do
    render conn, "privacy.html"
  end

  def terms(conn, _params) do
    render conn, "terms.html"
  end

  def contact(conn, _params) do
    render conn, "contact.html"
  end

  def test_crash(conn, _params) do
    # Intentionally crash so we can verify sentry alerts work.
    :ok = :error
    render conn, "index.html"
  end
end

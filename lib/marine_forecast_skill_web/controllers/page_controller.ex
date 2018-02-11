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
end

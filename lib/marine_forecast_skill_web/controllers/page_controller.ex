defmodule MarineForecastSkillWeb.PageController do
  use MarineForecastSkillWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end

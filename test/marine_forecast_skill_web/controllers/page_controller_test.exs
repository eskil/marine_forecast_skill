defmodule MarineForecastSkillWeb.PageControllerTest do
  use MarineForecastSkillWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Alexa Skill for Marine Weather Forecasts"
  end

  test "GET /privacy", %{conn: conn} do
    conn = get conn, "/privacy"
    assert html_response(conn, 200) =~ "Privacy Policy"
  end

  test "GET /terms", %{conn: conn} do
    conn = get conn, "/terms"
    assert html_response(conn, 200) =~ "Terms of Use"
  end

  test "GET /contact", %{conn: conn} do
    conn = get conn, "/contact"
    assert html_response(conn, 200) =~ "Contact"
  end
end

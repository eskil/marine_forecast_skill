defmodule MarineForecastSkillWeb.Api.AlexaController do
  use MarineForecastSkillWeb, :controller
  alias Alexa.Request
  require Logger

  def handle_request(conn, params) do
    request = Request.from_params(params)
    response = Alexa.handle_request(request)
    Logger.debug "Response = #{Poison.encode!(response)}"
    conn = send_resp(conn, 200, Poison.encode!(response))
    conn = %{conn | resp_headers: [{"content-type", "application/json"}]}
    conn
  end
end

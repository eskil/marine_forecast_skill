defmodule MarineForecastSkillWeb.Api.AlexaController do
  use MarineForecastSkillWeb, :controller
  require Logger

  def handle_request(conn, params) do
    alexa_request = Alexa.Request.from_params(params)
    alexa_response = Alexa.handle_request(alexa_request)
    Logger.debug "Response = #{Poison.encode!(alexa_response)}"
    conn = send_resp(conn, 200, Poison.encode!(alexa_response))
    conn = %{conn | resp_headers: [{"content-type", "application/json"}]}
    conn
  end
end

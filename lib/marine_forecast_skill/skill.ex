defmodule MarineForecastSkill.Skill do
  use Alexa.Skill, app_id: Application.get_env(:marine_forecast_skill, :amazon_skill_app_id)
  alias Alexa.{Request, Response}

  def handle_intent("GetForecast", _request, response) do
    response
    |> say("This is the marine forecast skill")
    |> should_end_session(true)
  end
end

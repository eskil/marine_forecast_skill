defmodule MarineForecastSkillWeb.Router do
  use MarineForecastSkillWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :alexa do
    plug Plug.Parsers,
      parsers: [AlexaVerifier.JSONParser],
      pass: ["*/*"],
      json_decoder: Poison

    # plug AlexaVerifier.Plug
  end

  scope "/api", MarineForecastSkillWeb.Api, as: :api do
    pipe_through :alexa

    post "/command", AlexaController, :handle_request
  end

  scope "/", MarineForecastSkillWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/privacy", PageController, :privacy
    get "/terms", PageController, :terms
    get "/contact", PageController, :contact
    get "/test_crash", PageController, :test_crash
  end

  # Other scopes may use custom stacks.
  # scope "/api", MarineForecastSkillWeb do
  #   pipe_through :api
  # end
end

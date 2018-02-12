# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :marine_forecast_skill, MarineForecastSkillWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "dun5PxjayWF9KXaVnRoumIe0jQUMtat/1tv3co2OJcX2JKVQlb29z08k6fKxfMZ7",
  render_errors: [view: MarineForecastSkillWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: MarineForecastSkill.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: Mix.env,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!,
  tags: %{},
  included_environments: [:prod]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

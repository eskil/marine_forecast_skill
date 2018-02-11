# MarineForecastSkill

Demo Amazon Alexa skill written in Elixir for Heroku deployment.

This skill will be invoked by phrases like
  * *alexa, ask marine forecast for today's weather*
  * *alexa, ask marine forecast for sunday's weather*

It fetches the data from
[NOAA](http://tgftp.nws.noaa.gov/data/raw/fz/fzus56.kmtr.cwf.mtr.txt),
parses via a small client library we'll write later to scrape for data
for station PZZ545 (coastal waters from Point Reyes to Pigeon Point).

## Create Amazon Skill

  * Skill information
    * Skill type, "Custom Interaction Model"
    * Name for display, "Marine Forecast"
    * Invocation name for accessing skill, "marine forecast"
  * Interaction model
    * Use the "Skill Builder Beta", but see below for an example.
  * Configuration
    * Service endpoint type, HTTPS
    * Default, https://<heroku-app>.herokuapp.com/api/command
    * Provide geographical endpoints, no
    * Account linking, no, since this is a simple demo, there's no user account settings.
    * Permissions, we don't need any of these, although a future iteration could use the device's zipcode to find the nearest station.
    * Privacy Policy URL, https://<heroku-app>.herokuapp.com/policy
  * SSL Certificate
    * Pick "My development endpoint is a sub-domain of a domain that has a wildcard certificate from a certificate authority"

Example interaction model used here.

```json
{
  "languageModel": {
    "intents": [
      {
        "name": "AMAZON.CancelIntent",
        "samples": []
      },
      {
        "name": "AMAZON.HelpIntent",
        "samples": []
      },
      {
        "name": "AMAZON.StopIntent",
        "samples": []
      },
      {
        "name": "GetForecast",
        "samples": [
          "ask marine forecast for {day} forecast",
          "check marine forecast for {day} forecast",
          "ask marine forecast about {day}"
        ],
        "slots": [
          {
            "name": "day",
            "type": "AMAZON.DayOfWeek"
          }
        ]
      }
    ],
    "invocationName": "marine forecast"
  }
}
```

## Create Phoenix App

Note that we pass `--no-ecto` to `phx.new` since we don't need a DB for this demo.

```sh
mix phx.new marine_forecast_skill --no-ecto
# Before answering yes to fetch and install dependencies
cd marine_forecast_skill/
git init .
git add *
git commit -m "Initial commit"
git remote add origin git@github.com:eskil/marine_forecast_skill.git
git push -u origin master
```

Create a heroku app and hook it up. I'm not going to go too much into
this, since https://hexdocs.pm/phoenix/heroku.html#content is
authorative here. But here's the unannotated steps.

```sh
heroku git:remote --app <heroku-app>
```

```sh
heroku buildpacks:add https://github.com/HashNuke/heroku-buildpack-elixir.git
heroku buildpacks:add https://github.com/gjaldon/heroku-buildpack-phoenix-static.git
heroku config:set SECRET_KEY_BASE=`mix phx.gen.secret`
```

```sh
echo "web: MIX_ENV=prod mix phx.server" > Procfile
git add Procfile
git commit -m "Heroku Procfile"
```

Prep `config/prod.exs` for heroku as per [the documentation](https://hexdocs.pm/phoenix/heroku.html#content)

```diff
diff --git a/config/prod.exs b/config/prod.exs
index 0c297e0..e0a1c55 100644
--- a/config/prod.exs
+++ b/config/prod.exs
@@ -15,8 +15,10 @@ use Mix.Config
 # which you typically run after static files are built.
 config :marine_forecast_skill, MarineForecastSkillWeb.Endpoint,
   load_from_system_env: true,
-  url: [host: "example.com", port: 80],
-  cache_static_manifest: "priv/static/cache_manifest.json"
+  url: url: [scheme: "https", host: "marine-forecast-skill.herokuapp.com", port: 443],
+  force_ssl: [rewrite_on: [:x_forwarded_proto]],
+  cache_static_manifest: "priv/static/cache_manifest.json",
+  secret_key_base: Map.fetch!(System.get_env(), "SECRET_KEY_BASE")

 # Do not print debug messages in production
 config :logger, level: :info
@@ -58,7 +60,3 @@ config :logger, level: :info
 #
 #     config :marine_forecast_skill, MarineForecastSkillWeb.Endpoint, server: true
 #
-
-# Finally import the config/prod.secret.exs
-# which should be versioned separately.
-import_config "prod.secret.exs"
```
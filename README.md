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
          "check marine forecast for {day}",
          "ask marine forecast about {day}",
          "ask marine forecast what is {day} forecast"
        ],
        "slots": [
          {
            "name": "day",
            "type": "AMAZON.DayOfWeek",
            "samples": [
              "{day}"
            ]
          }
        ]
      }
    ],
    "invocationName": "marine forecast"
  },
  "prompts": [
    {
      "id": "Elicit.Intent-GetForecast.IntentSlot-day",
      "variations": [
        {
          "type": "PlainText",
          "value": "which day did you want the forecast for?"
        }
      ]
    }
  ],
  "dialog": {
    "intents": [
      {
        "name": "GetForecast",
        "confirmationRequired": false,
        "prompts": {},
        "slots": [
          {
            "name": "day",
            "type": "AMAZON.DayOfWeek",
            "elicitationRequired": true,
            "confirmationRequired": false,
            "prompts": {
              "elicitation": "Elicit.Intent-GetForecast.IntentSlot-day"
            }
          }
        ]
      }
    ]
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
this, since [Phoenix on
Heroku](https://hexdocs.pm/phoenix/heroku.html#content) is authorative
here. But here's the unannotated steps.

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
index 0c297e0..52d427b 100644
--- a/config/prod.exs
+++ b/config/prod.exs
@@ -15,8 +15,10 @@ use Mix.Config
 # which you typically run after static files are built.
 config :marine_forecast_skill, MarineForecastSkillWeb.Endpoint,
   load_from_system_env: true,
-  url: [host: "example.com", port: 80],
-  cache_static_manifest: "priv/static/cache_manifest.json"
+  url: [scheme: "https", host: "marine-forecast-skill.herokuapp.com", port: 443],
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

Now you can push to heroku and all should be well.

```sh
git push heroku master
```

### Basic pages

To publish Alexa skills, you need some basic pages like privacy
policy, terms and use and contact info. So let's quickly just add
placeholders there.

First we add routes for the new pages.

```diff
diff --git a/lib/marine_forecast_skill_web/router.ex b/lib/marine_forecast_skill_web/router.ex
index 71359a0..c4339a1 100644
--- a/lib/marine_forecast_skill_web/router.ex
+++ b/lib/marine_forecast_skill_web/router.ex
@@ -17,6 +17,9 @@ defmodule MarineForecastSkillWeb.Router do
     pipe_through :browser # Use the default browser stack

     get "/", PageController, :index
+    get "/privacy", PageController, :privacy
+    get "/terms", PageController, :terms
+    get "/contact", PageController, :contact
   end

   # Other scopes may use custom stacks.
```

and entries in the `PageController` to access them.

```diff
diff --git a/lib/marine_forecast_skill_web/controllers/page_controller.ex b/lib/marine_forecast_skill_web/controllers/page_controller.ex
index febc676..1b3aa15 100644
--- a/lib/marine_forecast_skill_web/controllers/page_controller.ex
+++ b/lib/marine_forecast_skill_web/controllers/page_controller.ex
@@ -4,4 +4,16 @@ defmodule MarineForecastSkillWeb.PageController do
   def index(conn, _params) do
     render conn, "index.html"
   end
+
+  def privacy(conn, _params) do
+    render conn, "privacy.html"
+  end
+
+  def terms(conn, _params) do
+    render conn, "terms.html"
+  end
+
+  def contact(conn, _params) do
+    render conn, "contact.html"
+  end
 end
```

You'll now see these appear in your routes.

```bash
$ mix phx.routes
Compiling 1 file (.ex)
page_path  GET  /         MarineForecastSkillWeb.PageController :index
page_path  GET  /privacy  MarineForecastSkillWeb.PageController :privacy
page_path  GET  /terms    MarineForecastSkillWeb.PageController :terms
page_path  GET  /contact  MarineForecastSkillWeb.PageController :contact
```

We'll want to cleanup in home page a bit, just in case anyone lands
there. So we strip out most of the fluff from the generated index
page.

Remove the get-started link from the app page layout.

```diff
diff --git a/lib/marine_forecast_skill_web/templates/layout/app.html.eex b/lib/marine_forecast_skill_
index f5af8ae..71ce0a9 100644
--- a/lib/marine_forecast_skill_web/templates/layout/app.html.eex
+++ b/lib/marine_forecast_skill_web/templates/layout/app.html.eex
@@ -16,7 +16,6 @@
       <header class="header">
         <nav role="navigation">
           <ul class="nav nav-pills pull-right">
-            <li><a href="http://www.phoenixframework.org/docs">Get Started</a></li>
           </ul>
         </nav>
         <span class="logo"></span>
```

Strip down the index page to just link to the obligatory pages.

```diff
diff --git a/lib/marine_forecast_skill_web/templates/page/index.html.eex b/lib/marine_forecast_skill_web/templates/page/index.html.eex
index 0988ea5..686f11f 100644
--- a/lib/marine_forecast_skill_web/templates/page/index.html.eex
+++ b/lib/marine_forecast_skill_web/templates/page/index.html.eex
@@ -1,36 +1,14 @@
-<div class="jumbotron">
-  <h2><%= gettext "Welcome to %{name}!", name: "Phoenix" %></h2>
-  <p class="lead">A productive web framework that<br />does not compromise speed and maintainability.</p>
-</div>
-
 <div class="row marketing">
   <div class="col-lg-6">
-    <h4>Resources</h4>
+    <h4>A demo Alexa Skill for Marine Weather Forecasts.</h4>
+
     <ul>
-      <li>
-        <a href="http://phoenixframework.org/docs/overview">Guides</a>
-      </li>
-      <li>
-        <a href="https://hexdocs.pm/phoenix">Docs</a>
-      </li>
-      <li>
-        <a href="https://github.com/phoenixframework/phoenix">Source</a>
-      </li>
+      <li><a href="<%= page_path(@conn, :privacy) %>">Privacy</a>
+      <li><a href="<%= page_path(@conn, :terms) %>">Terms of Use</a>
+      <li><a href="<%= page_path(@conn, :contact) %>">Contact</a>
     </ul>
   </div>

   <div class="col-lg-6">
-    <h4>Help</h4>
-    <ul>
-      <li>
-        <a href="http://groups.google.com/group/phoenix-talk">Mailing list</a>
-      </li>
-      <li>
-        <a href="http://webchat.freenode.net/?channels=elixir-lang">#elixir-lang on freenode IRC</a>
-      </li>
-      <li>
-        <a href="https://twitter.com/elixirphoenix">@elixirphoenix</a>
-      </li>
-    </ul>
   </div>
 </div>
```

Every site needs a fancy icon, so we'll add one to the css.

```sh
git rm assets/static/images/phoenix.png
cp <your logo> assets/static/images/
git add assets/static/images/logo.png
```

```diff
diff --git a/assets/css/phoenix.css b/assets/css/phoenix.css
index 0b406d7..cd59f33 100644
--- a/assets/css/phoenix.css
+++ b/assets/css/phoenix.css
@@ -22,12 +22,12 @@ body, form, ul, table {
   border-bottom: 1px solid #e5e5e5;
 }
 .logo {
-  width: 519px;
-  height: 71px;
+  width: 100px;
+  height: 65px;
   display: inline-block;
   margin-bottom: 1em;
-  background-image: url("/images/phoenix.png");
-  background-size: 519px 71px;
+  background-image: url("/images/logo.png");
+  background-size: 100px 65px;
 }

 /* Everything but the jumbotron gets side spacing for mobile first views */
@@ -74,4 +74,4 @@ body, form, ul, table {
   .jumbotron {
     border-bottom: 0;
   }
-}
```

Now the home page is fairly simple an clean, and we just add blank
placeholders for the privacy/terms/contact pages for now. When you're
ready to get your app approved, you'll want to update them.

Add `lib/twsc_skill_web/templates/page/contact.html.eex`

```html
<div class="">
  <h2>Contact</h2>
  <p>Contact info goes here.
  </p>
</div>
```

Add `lib/twsc_skill_web/templates/page/privacy.html.eex`

```html
<div class="">
  <h2>Privacy Policy</h2>
  <p>Privacy policy goes here.
  </p>
</div>
```

Add `lib/twsc_skill_web/templates/page/terms.html.eex`

```html
<div class="">
  <h2>Terms of Use</h2>
  <p>Terms of use goes here.
  </p>
</div>
```

Fix up the unit-test for the changed `index.html` and add checks for the new pages.

```diff
diff --git a/test/marine_forecast_skill_web/controllers/page_controller_test.exs b/test/marine_forecast_skill_web/controllers/page_controller_test.exs
index 526710e..114e8da 100644
--- a/test/marine_forecast_skill_web/controllers/page_controller_test.exs
+++ b/test/marine_forecast_skill_web/controllers/page_controller_test.exs
@@ -3,6 +3,21 @@ defmodule MarineForecastSkillWeb.PageControllerTest do

   test "GET /", %{conn: conn} do
     conn = get conn, "/"
-    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
+    assert html_response(conn, 200) =~ "Alexa Skill for Marine Weather Forecasts"
+  end
+
+  test "GET /privacy", %{conn: conn} do
+    conn = get conn, "/privacy"
+    assert html_response(conn, 200) =~ "Privacy Policy"
+  end
+
+  test "GET /terms", %{conn: conn} do
+    conn = get conn, "/terms"
+    assert html_response(conn, 200) =~ "Terms of Use"
+  end
+
+  test "GET /contact", %{conn: conn} do
+    conn = get conn, "/contact"
+    assert html_response(conn, 200) =~ "Contact"
   end
 end
```

## Let's add Sentry

If you want extra error reporting etc, create a sentry org/project or
add Sentry as an add-on. I have an sentry.io account already, so I'll
add a sentry project, but in most cases, the
[addon](https://elements.heroku.com/addons/sentry) is probably easier.

When using your own org/project, get the DSN from Sentry, under
Settings/Client Keys (DSN).

```sh
heroku config:set SENTRY_DSN="<sentry dsn>"
```

Add the sentry dependencies. See
[here](https://docs.sentry.io/clients/elixir/) for the authoritative
documentation.

```diff
diff --git a/mix.exs b/mix.exs
index 18cc913..de30d26 100644
--- a/mix.exs
+++ b/mix.exs
@@ -19,7 +19,7 @@ defmodule MarineForecastSkill.Mixfile do
   def application do
     [
       mod: {MarineForecastSkill.Application, []},
-      extra_applications: [:logger, :runtime_tools]
+      extra_applications: [:sentry, :logger, :runtime_tools]
     ]
   end

@@ -37,7 +37,8 @@ defmodule MarineForecastSkill.Mixfile do
       {:phoenix_html, "~> 2.10"},
       {:phoenix_live_reload, "~> 1.0", only: :dev},
       {:gettext, "~> 0.11"},
-      {:cowboy, "~> 1.0"}
+      {:cowboy, "~> 1.0"},
+      {:sentry, "~> 6.1.0"}
     ]
   end
 end
```

Add the plug to our router, and while there, we'll add an endpoint to
trigger a crash to "test it in production".

```diff
diff --git a/lib/marine_forecast_skill_web/router.ex b/lib/marine_forecast_skill_web/router.ex
index c4339a1..9c258e0 100644
--- a/lib/marine_forecast_skill_web/router.ex
+++ b/lib/marine_forecast_skill_web/router.ex
@@ -1,5 +1,7 @@
 defmodule MarineForecastSkillWeb.Router do
   use MarineForecastSkillWeb, :router
+  use Plug.ErrorHandler
+  use Sentry.Plug

   pipeline :browser do
     plug :accepts, ["html"]
@@ -20,6 +22,7 @@ defmodule MarineForecastSkillWeb.Router do
     get "/privacy", PageController, :privacy
     get "/terms", PageController, :terms
     get "/contact", PageController, :contact
+    get "/test_crash", PageController, :test_crash
   end

   # Other scopes may use custom stacks.
```

And an endpoint in the controller that always crashes.

```diff
diff --git a/lib/marine_forecast_skill_web/controllers/page_controller.ex b/lib/marine_forecast_skill
_web/controllers/page_controller.ex
index 1b3aa15..dc15c3a 100644
--- a/lib/marine_forecast_skill_web/controllers/page_controller.ex
+++ b/lib/marine_forecast_skill_web/controllers/page_controller.ex
@@ -16,4 +16,10 @@ defmodule MarineForecastSkillWeb.PageController do
   def contact(conn, _params) do
     render conn, "contact.html"
   end
+
+  def test_crash(conn, _params) do
+    # Intentionally crash so we can verify sentry alerts work.
+    :ok = :error
+    render conn, "index.html"
+  end
 end
```

Note that this will cause a compiler warning because of the obvious
mismatch. So I suggest only having this while making sure things work
but then remove it again. And no endpoint is complete without a
unit-test.

```diff
diff --git a/test/marine_forecast_skill_web/controllers/page_controller_test.exs b/test/marine_forecast_skill_web/controllers/page_controller_test.exs
index 114e8da..01613cd 100644
--- a/test/marine_forecast_skill_web/controllers/page_controller_test.exs
+++ b/test/marine_forecast_skill_web/controllers/page_controller_test.exs
@@ -20,4 +20,10 @@ defmodule MarineForecastSkillWeb.PageControllerTest do
     conn = get conn, "/contact"
     assert html_response(conn, 200) =~ "Contact"
   end
+
+  test "GET /test_crash", %{conn: conn} do
+    assert_error_sent 500, fn ->
+      get conn, "/test_crash"
+    end
+  end
 end
```

Modify the prod config to setup sentry for `:prod` only and use this env.

```diff
diff --git a/config/prod.exs b/config/prod.exs
index 52d427b..c0fe5d0 100644
--- a/config/prod.exs
+++ b/config/prod.exs
@@ -23,6 +23,14 @@ config :marine_forecast_skill, MarineForecastSkillWeb.Endpoint,
 # Do not print debug messages in production
 config :logger, level: :info

+config :sentry,
+  dsn: System.get_env("SENTRY_DSN"),
+  environment_name: Mix.env,
+  enable_source_code_context: true,
+  root_source_code_path: File.cwd!,
+  tags: %{},
+  included_environments: [:prod]
+
 # ## SSL Support
 #
 # To get SSL working, you will need to add the `https` key
```

Push to heroku and goto https://<your-app>.herokuapp.com/test_crash,
you'll get an internal server error and a bit later the error will be
available in sentry.


## Add Alexa deps

We need two libraries for the alexa hookup.

   * [`col/alexa`](https://github.com/col/alexa), support for implementing alexa skills
   * [`col/alexa_verifier`](https://github.com/col/alexa_verifier), library to verify the cert on requests for you skill

NOTE: `alexa_verifier` from `col` is using an older version of `plug`,
so I'm using my fork that updates deps for now.

```diff
diff --git a/mix.exs b/mix.exs
index de30d26..0ea749c 100644
--- a/mix.exs
+++ b/mix.exs
@@ -19,7 +19,8 @@ defmodule MarineForecastSkill.Mixfile do
   def application do
     [
       mod: {MarineForecastSkill.Application, []},
-      extra_applications: [:sentry, :logger, :runtime_tools]
+      extra_applications: [:sentry, :logger, :runtime_tools,
+                           :alexa, :alexa_verifier]
     ]
   end

@@ -38,7 +39,9 @@ defmodule MarineForecastSkill.Mixfile do
       {:phoenix_live_reload, "~> 1.0", only: :dev},
       {:gettext, "~> 0.11"},
       {:cowboy, "~> 1.0"},
-      {:sentry, "~> 6.1.0"}
+      {:sentry, "~> 6.1.0"},
+      {:alexa, github: "col/alexa"},
+      {:alexa_verifier, github: "eskil/alexa_verifier"}
     ]
   end
 end
```

The verifier library needs to be configured.

```diff
diff --git a/config/config.exs b/config/config.exs
index 9a4081c..c2024a5 100644
--- a/config/config.exs
+++ b/config/config.exs
@@ -13,6 +13,9 @@ config :marine_forecast_skill, MarineForecastSkillWeb.Endpoint,
   pubsub: [name: MarineForecastSkill.PubSub,
            adapter: Phoenix.PubSub.PG2]

+config :alexa_verifier,
+  verifier_client: AlexaVerifier.VerifierClient
+
 # Configures Elixir's Logger
 config :logger, :console,
   format: "$time $metadata[$level] $message\n",
```

## Add the Alexa API route

Now we get to the meat of the matter. We add a pipeline for alexa api
calls that passes the message through `alexa_verifier` and a route for
the call itself.

```diff
diff --git a/lib/marine_forecast_skill_web/router.ex b/lib/marine_forecast_skill_web/router.ex
index 9c258e0..5c6b78c 100644
--- a/lib/marine_forecast_skill_web/router.ex
+++ b/lib/marine_forecast_skill_web/router.ex
@@ -15,6 +15,21 @@ defmodule MarineForecastSkillWeb.Router do
     plug :accepts, ["json"]
   end

+  pipeline :alexa do
+    plug Plug.Parsers,
+      parsers: [AlexaVerifier.JSONParser],
+      pass: ["*/*"],
+      json_decoder: Poison
+
+    plug AlexaVerifier.Plug
+  end
+
+  scope "/api", MarineForecastSkillWeb.Api, as: :api do
+    pipe_through :alexa
+
+    post "/command", AlexaController, :handle_request
+  end
+
   scope "/", MarineForecastSkillWeb do
     pipe_through :browser # Use the default browser stack
```

The controller itself is fairly simple. It simply creates an alexa request structure from the http request and a `handle_request` method calls out to the right module to actually handle the intent. We'll define that module afterwards. Define the controller in `lib/marine_forecast_skill_web/controllers/api/alexa_controller.ex`

```elixir
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
```

The connect a request to a handler, elixir alexa library registers a
module as a handler for an app id. This lets you support multiple
skills from the same app. So we need to configure an id, and in prod
use the real one but a mock one in test/dev.

```diff
diff --git a/config/config.exs b/config/config.exs
index c2024a5..9d58243 100644
--- a/config/config.exs
+++ b/config/config.exs
@@ -16,6 +16,9 @@ config :marine_forecast_skill, MarineForecastSkillWeb.Endpoint,
 config :alexa_verifier,
   verifier_client: AlexaVerifier.VerifierClient

+config :marine_forecast_skill,
+  amazon_skill_app_id: "MarineForecastSkill"
+
 # Configures Elixir's Logger
 config :logger, :console,
   format: "$time $metadata[$level] $message\n",
```

and in prod we pull it from an environment variable.

```diff
diff --git a/config/prod.exs b/config/prod.exs
index 52d427b..0001d79 100644
--- a/config/prod.exs
+++ b/config/prod.exs
@@ -23,6 +23,9 @@ config :marine_forecast_skill, MarineForecastSkillWeb.Endpoint,
 # Do not print debug messages in production
 config :logger, level: :info

+config :marine_forecast_skill,
+  amazon_skill_app_id: System.get_env("AMAZON_SKILL_APP_ID")
+
 # ## SSL Support
 #
 # To get SSL working, you will need to add the `https` key
```

In the Amazon developer console, there's the skill ID right under your
skill name. It looks like `amzn1.ask.skill.<uuid>`. Copy that and
configure in your runtime environment.

```sh
heroku config:set AMAZON_SKILL_APP_ID="amzn1.ask.skill.<uuid>"
```

We put the first simple handler in `lib/marine_forecast_skill/skill.ex`.

```elixir
defmodule MarineForecastSkill.Skill do
  use Alexa.Skill, app_id: Application.get_env(:marine_forecast_skill, :amazon_skill_app_id)
  alias Alexa.{Request, Response}

  def handle_intent("GetForecast", _request, response) do
    response
    |> say("This is the marine forecast skill")
    |> should_end_session(true)
  end
end
```

To get it registered at launch time, we make our application start the
process as a worker.

```diff
diff --git a/lib/marine_forecast_skill/application.ex b/lib/marine_forecast_skill/application.ex
index 6c3563f..fe07ba8 100644
--- a/lib/marine_forecast_skill/application.ex
+++ b/lib/marine_forecast_skill/application.ex
@@ -11,7 +11,7 @@ defmodule MarineForecastSkill.Application do
       # Start the endpoint when the application starts
       supervisor(MarineForecastSkillWeb.Endpoint, []),
       # Start your own worker by calling: MarineForecastSkill.Worker.start_link(arg1, arg2, arg3)
-      # worker(MarineForecastSkill.Worker, [arg1, arg2, arg3]),
+      worker(MarineForecastSkill.Skill, [[app_id: Application.get_env(:river_place_app, :app_id)]]),
     ]

     # See https://hexdocs.pm/elixir/Supervisor.html
```

## Testing it locally

You can test call by grabbing a sample json blob from Amazon's
developer console under the test tab. It lets you enter/dictate an utterance and shows the json blob posted to the configured endpoint.

It can be posted directly to the locally running server. You have to
renamed the `applicationId` to whatever you configured as app id in
`config.exs`.

```sh
curl --request POST \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data @misc/sample-request.json \
  "http://0.0.0.0:4000/api/command"
```

The response is

```json
{
  "version": "1.0",
  "sessionAttributes": {},
  "response": {
    "shouldEndSession": true,
    "reprompt": null,
    "outputSpeech": {
      "type": "PlainText",
      "text": "This is the marine forecast skill",
      "ssml": null
    },
    "directives": [],
    "card": null
  }
}
```

So now we're ready and "just" need to write a client that can call
noaa and parse out the weather data.

NOTE: the code in `deps/alexa/lib/alexa/skill.ex` suggests the skill
code is 1-1 with the skill process. That might be worth hacking up.

NOTE: I'm now stuck on this, the verifier isn't configured
properly. Turns out I don't need the verifier for testing, it works
fine without it? But I'm sure it's necessary in prod.

```
2018-02-12T06:54:51.545350+00:00 app[web.1]: Request: POST /api/command
2018-02-12T06:54:51.545353+00:00 app[web.1]: ** (exit) an exception was raised:
2018-02-12T06:54:51.545355+00:00 app[web.1]:     ** (ArgumentError) argument error
2018-02-12T06:54:51.545358+00:00 app[web.1]:         (alexa_verifier) lib/alexa_verifier/verifier_client.ex:5: AlexaVerifier.VerifierClient.process_url/1
2018-02-12T06:54:51.545359+00:00 app[web.1]:         (alexa_verifier) lib/alexa_verifier/verifier_client.ex:2: AlexaVerifier.VerifierClient.request/5
2018-02-12T06:54:51.545361+00:00 app[web.1]:         (alexa_verifier) lib/alexa_verifier/verifier_client.ex:2: AlexaVerifier.VerifierClient.request!/5
2018-02-12T06:54:51.545363+00:00 app[web.1]:         (alexa_verifier) lib/alexa_verifier/verifier_client.ex:21: AlexaVerifier.VerifierClient.verify/3
2018-02-12T06:54:51.545365+00:00 app[web.1]:         (alexa_verifier) lib/alexa_verifier/plug.ex:30: AlexaVerifier.Plug.verify_request/2
2018-02-12T06:54:51.545367+00:00 app[web.1]:         (alexa_verifier) lib/alexa_verifier/plug.ex:1: AlexaVerifier.Plug.plug_builder_call/2
2018-02-12T06:54:51.545369+00:00 app[web.1]:         (marine_forecast_skill) lib/marine_forecast_skill_web/router.ex:18: MarineForecastSkillWeb.Router.alexa/2
2018-02-12T06:54:51.545372+00:00 app[web.1]:         (marine_forecast_skill) lib/marine_forecast_skill_web/router.ex:1: anonymous fn/1 in MarineForecastSkillWeb.Router.__match_route__/4
```
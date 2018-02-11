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
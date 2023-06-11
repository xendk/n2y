require "dotenv"
require "kemal"
require "multi_auth"
require "raven"
require "raven/integrations/kemal"
require "./n2y"
require "./n2y/ynab"
require "./n2y/user"
require "sqlite3"

Dotenv.load

raise "Please set GOOGLE_CLIENT_ID" unless ENV["GOOGLE_CLIENT_ID"]?
raise "Please set GOOGLE_CLIENT_SECRET" unless ENV["GOOGLE_CLIENT_SECRET"]?

MultiAuth.config(
  "google",
  ENV["GOOGLE_CLIENT_ID"],
  ENV["GOOGLE_CLIENT_SECRET"]
)

N2y::User.configure do |settings|
  settings.db = DB.open ENV["N2Y_DB_URL"]? || N2y::DEFAULT_DB_URL
end

N2y::YNAB.configure do |settings|
  settings.client_id = ENV["YNAB_CLIENT_ID"]? || raise "YNAB_CLIENT_ID not set"
  settings.secret = ENV["YNAB_SECRET"]? || raise "YNAB_SECRET not set"
end

Raven.configure do |config|
  # Keep main fiber responsive by sending the events in the background.
  config.async = true
  # Set the environment name using `Kemal.config.env`, which uses `KEMAL_ENV` variable under-the-hood.
  config.current_environment = Kemal.config.env
end

# Capture logs to Sentry.
if Kemal.config.env == "development"
  # ... but log to STDOUT too in development.
  Kemal.config.logger = Raven::Kemal::LogHandler.new(Kemal::LogHandler.new)
else
  Kemal.config.logger = Raven::Kemal::LogHandler.new()
end

# Capture exceptions to Sentry.
Kemal.config.add_handler Raven::Kemal::ExceptionHandler.new

FileUtils.mkdir_p ENV["SESSION_DIR"] if ENV["SESSION_DIR"]?

Kemal::Session.config do |config|
  config.cookie_name = "n2y_session_id"
  config.secret = "super-secret"
  config.secret = ENV["SESSION_SECRET"]? || raise "SESSION_SECRET not set"
  config.gc_interval = 2.minutes # 2 minutes
  if ENV["SESSION_DIR"]?
    config.engine = Kemal::Session::FileEngine.new({:sessions_dir => ENV["SESSION_DIR"]})
  end
end

require "./n2y/app"

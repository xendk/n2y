require "dotenv"
# Load .env file before requiring kemal, else it doesn't pick up
# KEMAL_ENV from the file.
Dotenv.load

require "kemal"
require "file_utils"
require "multi_auth"
require "raven"
require "raven/integrations/kemal"
require "log"
require "http/cookie"
require "./n2y"
require "./n2y/nordigen"
require "./n2y/ynab"
require "./n2y/user"
require "./n2y/bank"
require "./n2y/budget"
require "./n2y/rotating_backend"
require "./n2y/app"

raise "Please set GOOGLE_CLIENT_ID" unless ENV["GOOGLE_CLIENT_ID"]?
raise "Please set GOOGLE_CLIENT_SECRET" unless ENV["GOOGLE_CLIENT_SECRET"]?

MultiAuth.config(
  "google",
  ENV["GOOGLE_CLIENT_ID"],
  ENV["GOOGLE_CLIENT_SECRET"]
)

Dir.mkdir_p "storage/users"
N2y::User.configure do |settings|
  settings.storage_path = "storage/users"
end

N2y::User.load_from_disk

Dir.mkdir_p "storage/logs"
N2y::RotatingBackend.configure do |settings|
  settings.storage_path = "storage/logs"
end

Log.setup do |c|
  # Capture all logs if DEBUG env variable is set.
  if ENV["DEBUG"]?
    c.bind "*", :trace, Log::IOBackend.new(STDOUT)
  end
  c.bind "n2y.user", :debug, N2y::RotatingBackend.new
end

N2y::Nordigen.configure do |settings|
  settings.secret_id = ENV["NORDIGEN_SECRET_ID"]? || raise "NORDIGEN_SECRET_ID not set"
  settings.secret = ENV["NORDIGEN_SECRET"]? || raise "NORDIGEN_SECRET not set"
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
  # Use tags as release name.
  config.release = Raven.sys_command_compiled("git describe --tags --always HEAD")
end

def log_exception(ex)
  Kemal.config.env == "production" ? Raven.capture(ex) : log("Exception: #{ex.inspect_with_backtrace}")
end

# Capture logs to Sentry.
if Kemal.config.env == "development"
  # ... but log to STDOUT too in development.
  Kemal.config.logger = Raven::Kemal::LogHandler.new(Kemal::LogHandler.new)
else
  Kemal.config.logger = Raven::Kemal::LogHandler.new
end

# Capture exceptions to Sentry.
Kemal.config.add_handler Raven::Kemal::ExceptionHandler.new

FileUtils.mkdir_p ENV["SESSION_DIR"] if ENV["SESSION_DIR"]?

Kemal::Session.config do |config|
  # Give sessions a decent lifetime, we'll enforce re-authentication
  # ourselves.
  config.timeout = 2.weeks
  config.cookie_name = "n2y_session_id"
  config.samesite = HTTP::Cookie::SameSite::Lax
  config.secure = Kemal.config.env == "production"
  config.secret = ENV["SESSION_SECRET"]? || raise "SESSION_SECRET not set"
  config.gc_interval = 2.minutes
  if ENV["SESSION_DIR"]?
    config.engine = Kemal::Session::FileEngine.new({:sessions_dir => ENV["SESSION_DIR"]})
  end
end

# Systemd sends SIGTERM per default, so gracefully shut down.
Signal::TERM.trap do
  log "#{Kemal.config.app_name} closing down"
  Kemal.stop
  N2y::User.save_to_disk
  exit
end

Signal::INT.trap do
  log "#{Kemal.config.app_name} is going to take a rest!" if Kemal.config.shutdown_message
  Kemal.stop
  N2y::User.save_to_disk
  exit
end

Habitat.raise_if_missing_settings!

# We've set up our own signal handling, so disable Kemal's.
Kemal.run(trap_signal: false)

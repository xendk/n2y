require "spec"
require "../src/n2y/user"
# Mock all HTTP requests.
require "webmock"

# Use a temporary database for testing.
DB_FIXURE = "/tmp/n2y-spec.db"
DB_URL = "sqlite3://#{DB_FIXURE}"
ENV["N2Y_DB_URL"] = DB_URL
ENV["SESSION_SECRET"] = "super secret"

# Set up a database fixture.
def load_fixture(name)
  File.delete? DB_FIXURE
  system("sqlite3 #{DB_FIXURE} < spec/fixtures/#{name}.sql")
  N2y::User.settings.db = DB.open DB_URL
end

N2y::User.configure do |settings|
  settings.db = DB.open DB_URL
end

Kemal::Session.config do |config|
  config.cookie_name = "n2y_session_id"
  config.secret = ENV["SESSION_SECRET"]? || raise "SESSION_SECRET not set"
  config.gc_interval = 2.minutes # 2 minutes
end

# This is defined by server.cr, so make it available.
def log_exception(ex)
  raise ex
end

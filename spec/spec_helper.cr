require "spec"
require "../src/n2y/user"
# Mock all HTTP requests.
require "webmock"
require "kemal"

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

# Use another port for testing.
Kemal.config.port = 3001

# This is defined by server.cr, so make it available.
def log_exception(ex)
  raise ex
end

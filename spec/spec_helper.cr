require "spec"
require "../src/n2y/user"

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

require "spec"
require "../src/n2y/database"

# Use a temporary database for testing.
DB_FIXURE = "/tmp/n2y-spec.db"
DB_URL = "sqlite3://#{DB_FIXURE}"
ENV["N2Y_DB_URL"] = DB_URL
ENV["SESSION_SECRET"] = "super secret"

# Set up a database fixture.
def load_fixture(name)
  File.delete? DB_FIXURE
  N2y::Db::INSTANCE.refresh
  system("sqlite3 #{DB_FIXURE} < spec/fixtures/#{name}.sql")
end

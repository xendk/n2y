require "./n2y"
require "micrate"
require "sqlite3"

module N2y
  Micrate::DB.connection_url = ENV["N2Y_DB_URL"]? || DEFAULT_DB_URL
  Micrate::Cli.run
end

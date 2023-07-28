# TODO: Write documentation for `N2y`
module N2y
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}

  DEFAULT_DB_URL = "sqlite3://./db/n2y.db"
end

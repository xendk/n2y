require "../n2y"
require "sqlite3"

module N2y
  class Db
    INSTANCE = new
    @db : DB::Database

    private def initialize
      @db = DB.open ENV["N2Y_DB_URL"]? || DEFAULT_DB_URL
    end

    def refresh
      @db = DB.open ENV["N2Y_DB_URL"]? || DEFAULT_DB_URL
    end

    # Get current user or nil.
    def user?(mail)
      @db.query_one?("SELECT mail FROM users WHERE mail = ?", mail, as: String)
    end

    # Create new user.
    def add_user(mail)
      @db.exec "INSERT INTO users (mail) VALUES (?)", mail
    end
  end
end

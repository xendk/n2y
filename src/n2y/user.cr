require "../n2y"
require "sqlite3"
require "habitat"
require "log"
require "./token_pair"

module N2y
  class User
    Log = ::Log.for(self)

    Habitat.create do
      setting db : DB::Database
    end

    @@users = {} of String => User

    getter mail : String
    getter? exists : Bool = false
    property nordigen_requisition_id : String?
    property ynab_refresh_token : String?

    def self.get(mail : String)
      (@@users[mail] ||= User.new(mail)).tap &.load
    end

    # Clear cache of users. Primarily for testing.
    def self.clear_cache
      @@users = {} of String => User
    end

    def initialize(mail : String)
      @mail = mail
    end

    def load
      @exists = false
      row = settings.db.query_one? <<-SQL, mail, as: {String, String?, String?, String?}
SELECT mail, nordigen_requisition_id, ynab_refresh_token FROM users WHERE mail = ?
SQL
      if row
        @mail, @nordigen_requisition_id, @ynab_refresh_token = row
        @exists = true
      end
    end

    def save
      if exists?
        settings.db.exec <<-SQL, nordigen_requisition_id, ynab_refresh_token, mail
UPDATE users SET nordigen_requisition_id = ?, ynab_refresh_token = ? WHERE mail = ?
SQL
      else
        settings.db.exec <<-SQL, mail, nordigen_requisition_id, ynab_refresh_token
INSERT INTO users (mail, nordigen_requisition_id, ynab_refresh_token) VALUES (?, ?, ?)
SQL
        @exists = true
      end
    end

    def ynab_token_pair
      @token_pair ||= TokenPair.new(refresh: ynab_refresh_token) do |token|
        if @ynab_refresh_token != token.refresh?
          @ynab_refresh_token = token.refresh
          save
        end
      end
    end

    # Get log entries for this user.
    def log_entries
      entries = [] of NamedTuple(timestamp: String, severity: String, message: String, data: String)
      settings.db.query "select timestamp, severity, message, data from log where mail = ? order by timestamp desc", @mail do |rs|
        rs.each do
          timestamp = Time.unix(rs.read(Int32)).to_rfc3339
          severity = rs.read(String)
          message = rs.read(String)
          data = rs.read(String)

          entries << {timestamp: timestamp, severity: severity, message: message, data: data}
        end
      end

      entries
    end
  end
end

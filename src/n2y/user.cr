require "../n2y"
require "sqlite3"
require "habitat"

module N2y
  class User
    Habitat.create do
      setting db : DB::Database
    end

    @@users = {} of String => User

    getter mail : String
    getter? exists : Bool = false
    getter nordigen_requisition_id : String?
    getter nordigen_bank_id : String?
    getter ynab_refresh_token : String?

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
SELECT mail, nordigen_requisition_id, nordigen_bank_id, ynab_refresh_token FROM users WHERE mail = ?
SQL
      if row
        @mail, @nordigen_requisition_id, @nordigen_bank_id, @ynab_refresh_token = row
        @exists = true
      end
    end

    def save
      if exists?
        settings.db.exec <<-SQL, nordigen_requisition_id, nordigen_bank_id, ynab_refresh_token, mail
UPDATE users SET nordigen_requisition_id = ?, nordigen_bank_id = ?, ynab_refresh_token = ? WHERE mail = ?
SQL
      else
        settings.db.exec <<-SQL, mail, nordigen_requisition_id, nordigen_bank_id, ynab_refresh_token
INSERT INTO users (mail, nordigen_requisition_id, nordigen_bank_id, ynab_refresh_token) VALUES (?, ?, ?, ?)
SQL
        @exists = true
      end
    end
  end
end

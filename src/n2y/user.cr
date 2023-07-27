require "../n2y"
require "yaml"
require "sqlite3"
require "habitat"
require "log"
require "./token_pair"

module N2y
  class User
    include YAML::Serializable

    Log = ::Log.for(self)

    Habitat.create do
      setting storage_path : String
      setting db : DB::Database
    end

    @@users = {} of String => User

    getter mail : String
    property nordigen_requisition_id : String?
    property ynab_refresh_token : String?
    property last_sync_time : Time = Time.unix(0)
    property mapping = {} of String => NamedTuple(id: String, budget_id: String)
    property id_seed = ""

    @[YAML::Field(ignore: true)]
    @token_pair : TokenPair?

    def self.load_from_disk
      @@users = {} of String => User
      Dir.glob(File.join(settings.storage_path, "*.yml")) do |path|
        mail = File.basename(path, ".yml")
        @@users[mail] = User.from_yaml(File.read(path))
      end
    end

    def self.save_to_disk
      @@users.each_value do |user|
        user.save
      end
    end

    def self.migrate
      if Dir.glob(File.join(settings.storage_path, "*.yml")).empty?
        Log.info { "Migrating from SQLite to YAML storage" }
        users = [] of String
        settings.db.query "SELECT mail FROM users" do |rs|
          rs.each do
            users << rs.read(String)
          end
        end
        users.each do |mail|
          user = User.get(mail)
          user.load_from_db
          user.save
        end
      end
    end

    def self.get(mail : String)
      @@users[mail] ||= User.new(mail)
    end

    def initialize(@mail : String)
    end

    def path
      File.join(settings.storage_path, "#{@mail}.yml")
    end

    def exists?
      File.exists?(path)
    end

    def load_from_db
      row = settings.db.query_one? <<-SQL, mail, as: {String, String?, String?, String, String, Int32}
SELECT
  mail,
  nordigen_requisition_id,
  ynab_refresh_token,
  id_seed,
  mapping,
  last_sync_time
FROM users WHERE mail = ?
SQL
      if row
        @mail, @nordigen_requisition_id, @ynab_refresh_token, @id_seed = row
        if row[4] != ""
          @mapping = (Hash(String, NamedTuple(id: String, budget_id: String))).from_json(row[4])
        end
        @last_sync_time = Time.unix(row[5])
      end
    end

    def save
      File.write(path, to_yaml)
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

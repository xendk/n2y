require "log"
require "habitat"
require "sqlite3"
require "log/json"

class N2y::DatabaseLogBackend < Log::Backend
  Habitat.create do
    setting db : DB::Database
  end

  def write(entry : Log::Entry) : Nil
    sql = <<-SQL
INSERT INTO log (timestamp, mail, severity, message, data) VALUES (?, ?, ?, ?, ?)
SQL
    settings.db.exec sql,
      entry.timestamp.to_unix.to_s,
      entry.context[:user_id].as_s,
      entry.severity.label,
      entry.message,
      entry.data[:json]? ? entry.data[:json].as_s : ""
  end
end

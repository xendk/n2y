require "spec"
require "../src/n2y/user"
# Mock all HTTP requests.
require "webmock"
ENV["KEMAL_ENV"] = "test"
require "kemal"

ENV["SESSION_SECRET"] = "super secret"

N2y::User.configure do |settings|
  settings.storage_path = "/tmp/n2y-test/storage/user"
end

def clear_users
  tmp_dir = "/tmp/n2y-test/storage/user"
  FileUtils.rm_rf tmp_dir
  Dir.mkdir_p tmp_dir

  N2y::User.load_from_disk
end

# Use another port for testing.
Kemal.config.port = 3001

# This is defined by server.cr, so make it available.
def log_exception(ex)
  raise ex
end

require "../spec_helper"
require "file_utils"
require "../../src/n2y/rotating_backend"

include N2y

def with_storage(&)
  tmp_dir = "/tmp/n2y-test/storage/logs"
  FileUtils.rm_rf tmp_dir
  Dir.mkdir_p tmp_dir

  RotatingBackend.settings.storage_path = "/tmp/n2y-test/storage/logs"

  yield
end

describe RotatingBackend do
  it "should write to user log file" do
    with_storage do
      Log.with_context do
        Log.context.set user_id: "test"

        entry = Log::Entry.new(
          "here",
          Log::Severity::Error,
          "log message",
          Log::Metadata.new(nil, {json: "{}"}),
          nil,
          timestamp: Time.utc(2023, 5, 17, 18, 35, 27)
        )

        RotatingBackend.new.write(entry)

        entry = Log::Entry.new(
          "here2",
          Log::Severity::Error,
          "second log message",
          Log::Metadata.new(nil),
          nil,
          timestamp: Time.utc(2023, 5, 17, 18, 35, 35)
        )

        RotatingBackend.new.write(entry)

        File.exists?("/tmp/n2y-test/storage/logs/test/2023-05-17.log").should eq true
        File.read("/tmp/n2y-test/storage/logs/test/2023-05-17.log").should eq "2023-05-17T18:35:27.000000Z\tERROR\tlog message\t{}\n2023-05-17T18:35:35.000000Z\tERROR\tsecond log message\n"
      end
    end
  end

  it "should rotate log files" do
    with_storage do
      Log.with_context do
        Log.context.set user_id: "test"

        entry = Log::Entry.new(
          "here",
          Log::Severity::Error,
          "log message",
          Log::Metadata.new(nil, {json: "{}"}),
          nil,
          timestamp: Time.utc(2023, 5, 17, 18, 35, 27)
        )

        RotatingBackend.new.write(entry)

        entry = Log::Entry.new(
          "here2",
          Log::Severity::Error,
          "second log message",
          Log::Metadata.new(nil),
          nil,
          timestamp: Time.utc(2023, 5, 18, 18, 35, 35)
        )

        RotatingBackend.new.write(entry)

        File.exists?("/tmp/n2y-test/storage/logs/test/2023-05-17.log").should eq true
        File.exists?("/tmp/n2y-test/storage/logs/test/2023-05-18.log").should eq true
        File.read("/tmp/n2y-test/storage/logs/test/2023-05-17.log").should eq "2023-05-17T18:35:27.000000Z\tERROR\tlog message\t{}\n"
        File.read("/tmp/n2y-test/storage/logs/test/2023-05-18.log").should eq "2023-05-18T18:35:35.000000Z\tERROR\tsecond log message\n"
      end
    end
  end
end

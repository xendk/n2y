require "log"
require "habitat"
require "log/json"
require "file_utils"

module N2y
  class RotatingBackend < Log::Backend
    Habitat.create do
      setting storage_path : String
    end

    class TabFormat
      extend Log::Formatter

      def self.format(entry : Log::Entry, io : IO)
        entry.timestamp.to_rfc3339(io, fraction_digits: 6)
        io << "\t"
        io << entry.severity.label
        io << "\t"
        io << entry.message.gsub('\t', ' ')
        if entry.data[:json]?
          io << "\t"
          io << entry.data[:json].as_s
        end
      end
    end

    @formatter = TabFormat
    @daystamp : Int32?
    @files = {} of String => IO

    def initialize
      @mutex = Mutex.new(:unchecked)
      # Async segfaults, see https://github.com/crystal-lang/crystal/issues/13721
      super(dispatch_mode: Log::DispatchMode::Sync)
    end

    def write(entry : Log::Entry)
      @mutex.synchronize do
        daystamp = (entry.timestamp.year * 10000) +
                   (entry.timestamp.month * 100) +
                   (entry.timestamp.day)

        # New day, close open files.
        close if daystamp != @daystamp

        user_id = entry.context[:user_id].as_s

        if @files[user_id]?.nil?
          directory = File.join(settings.storage_path, user_id)
          Dir.mkdir_p directory
          filename = "%04d-%02d-%02d.log" % entry.timestamp.try { |d| [d.year, d.month, d.day] }
          @files[user_id] = File.open(File.join(directory, filename), "a")
        end

        format(entry, @files[user_id])
        @files[user_id].puts
        @files[user_id].flush
      end
    end

    # Emits the *entry* to the given *io*.
    # It uses the `#formatter` to convert.
    def format(entry : Log::Entry, io : IO)
      @formatter.format(entry, io)
    end

    def close
      @files.each_value { |io| io.close }
      @files = {} of String => IO
    end
  end
end

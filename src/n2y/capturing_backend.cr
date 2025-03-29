require "log"

module N2y
  class CapturingBackend < Log::Backend

    INSTANCE = new

    protected property log : Array(String)?

    private def initialize
      super(dispatch_mode: Log::DispatchMode::Sync)
    end

    def write(entry : Log::Entry)
      if log = @log
        log << entry.message
      end
    end

    def self.capture : Array(String)
      CapturingBackend::INSTANCE.log = [] of String

      yield

      CapturingBackend::INSTANCE.log || [] of String
    ensure
      CapturingBackend::INSTANCE.log = nil
    end
  end
end

require "../spec_helper"
require "../../src/n2y/capturing_backend"

include N2y

describe CapturingBackend do
  it "should capture log entries" do
    Log.setup(:debug, CapturingBackend::INSTANCE)

    log = CapturingBackend.capture do
      Log.info { "this is a test" }
    end

    log.should eq ["this is a test"]
  end

  it "shouldn't capture log entries outside the block" do
    Log.setup(:debug, CapturingBackend::INSTANCE)

    Log.info { "this shouldn't show up"}

    log = CapturingBackend.capture do
      Log.info { "this is a test" }
      Log.info { "another test" }
    end

    Log.info { "neither should this"}

    log.should eq ["this is a test", "another test"]
  end
end

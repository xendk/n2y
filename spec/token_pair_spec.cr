require "./spec_helper"
require "../src/n2y/token_pair"

include N2y

describe TokenPair do
  it "manages an access token" do
    pair = TokenPair.new

    pair.access?.should be_falsey
    expect_raises(NilAssertionError) do
      pair.access
    end

    pair.access = "foo"
    pair.access?.should be_truthy
    pair.access.should be "foo"
  end

  it "manages a refresh token" do
    pair = TokenPair.new

    pair.refresh?.should be_falsey
    expect_raises(NilAssertionError) do
      pair.refresh
    end

    pair.refresh = "foo"
    pair.refresh?.should be_truthy
    pair.refresh.should be "foo"
  end

  it "allows for invalidating tokens" do
    pair = TokenPair.new

    pair.access = "foo"
    pair.refresh = "bar"

    pair.invalidate_access
    pair.access?.should be_falsey
    pair.refresh?.should be("bar")

    # Invalidating refresh should invalidate access too.
    pair.access = "baz"
    pair.invalidate_refresh
    pair.access?.should be_falsey
    pair.refresh?.should be_falsey

    pair.access = "qux"
    pair.refresh = "quux"
    pair.invalidate
    pair.access?.should be_falsey
    pair.refresh?.should be_falsey
  end

  it "can be initialized with tokens" do
    pair = TokenPair.new(access: "foo", refresh: "bar")

    pair.access.should be "foo"
    pair.refresh.should be "bar"
  end

  it "it can notify observers of changes to access token" do
    pair = TokenPair.new(access: "foo", refresh: "bar")

    val = nil

    pair.on_access_change do |token|
      val = token.access
    rescue
        val = nil
    end

    val.should be_nil
    pair.access = "baz"
    val.should be "baz"

    pair.invalidate_access
    val.should be_nil
  end

  it "it can notify observers of changes to refesh token" do
    pair = TokenPair.new(access: "foo", refresh: "bar")

    val = nil

    pair.on_refresh_change do |token|
      val = token.refresh
    rescue
        val = nil
    end

    val.should be_nil
    pair.refresh = "baz"
    val.should be "baz"

    pair.invalidate_refresh
    val.should be_nil
  end

  it "can tell if it's usable" do
    TokenPair.new().usable?.should be_falsey
    TokenPair.new(access: "foo").usable?.should be_truthy
    TokenPair.new(refresh: "foo").usable?.should be_truthy
  end
end

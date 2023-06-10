require "./spec_helper"
require "../src/n2y/nordigen"

load_fixture("just-one-user")

include N2y

describe User do
  describe ".get" do
    it "returns a user for any string" do
      User.get("any string").class.should eq(User)
    end

    it "returns the same user on the same string" do
      user1 = User.get("any string")
      user2 = User.get("any string")

      user1.should be(user2)
    end
  end

  describe "#exists?" do
    it "returns true if the user exists" do
      User.get("existing-user@gmail.com").exists?.should be_true
    end

    it "returns false if the user does not exist" do
      User.get("any other string").exists?.should be_false
    end
  end

  it "should save the user" do
    user = User.get("any string")
    user.save
    User.clear_cache

    user = User.get("any string")
    user.exists?.should be_true
  end
end

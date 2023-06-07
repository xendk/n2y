require "./spec_helper"
require "../src/n2y/nordigen"

load_fixture("just-one-user")

describe N2y::User do
  describe ".get" do
    it "returns a user for any string" do
      N2y::User.get("any string").class.should eq(N2y::User)
    end

    it "returns the same user on the same string" do
      user1 = N2y::User.get("any string")
      user2 = N2y::User.get("any string")

      user1.should be(user2)
    end
  end

  describe "#exists?" do
    it "returns true if the user exists" do
      N2y::User.get("existing-user@gmail.com").exists?.should be_true
    end

    it "returns false if the user does not exist" do
      N2y::User.get("any other string").exists?.should be_false
    end
  end

  it "should save the user" do
    user = N2y::User.get("any string")
    user.save
    user.load

    user.exists?.should be_true
  end
end

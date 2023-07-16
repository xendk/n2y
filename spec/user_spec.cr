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

  it "provides an YNAB TokenPair which saves on changes" do
    user = User.get("tokentest")
    user.ynab_token_pair.refresh?.should be_falsey
    user.ynab_token_pair.refresh = "refresh"

    User.clear_cache
    user = User.get("tokentest")
    user.ynab_token_pair.refresh.should eq("refresh")
  end

  it "stores account mapping" do
    mapping = {} of String => NamedTuple(id: String, budget_id: String)

    mapping["account1"] = {id: "id1", budget_id: "budget_id1"}
    mapping["account2"] = {id: "id2", budget_id: "budget_id2"}

    User.clear_cache
    user = User.get("tokentest")

    user.mapping = mapping
    user.mapping.should eq(mapping)
  end
end

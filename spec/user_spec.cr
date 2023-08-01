require "./spec_helper"
require "file_utils"

load_fixture("just-one-user")

include N2y

describe User do
  describe ".get" do
    it "returns a user for any string" do
      User.get("any_string").class.should eq(User)
    end

    it "returns the same user on the same string" do
      user1 = User.get("any_string")
      user2 = User.get("any_string")

      user1.should be(user2)
    end
  end

  describe "#exists?" do
    it "returns true if the user exists" do
      clear_users

      User.get("existing-user@gmail.com").save
      User.get("existing-user@gmail.com").exists?.should be_true
    end

    it "returns false if the user does not exist" do
      clear_users

      User.get("any other string").exists?.should be_false
    end
  end

  it "should save the user" do
    clear_users

    user = User.get("any_string")
    File.exists?(user.path).should be_false
    user.save

    File.exists?(user.path).should be_true
    File.read(user.path).should eq("---\nmail: any_string\nlast_sync_time: 1970-01-01\nmapping: {}\nid_seed: \"\"\n")
  end

  it "should save all users to disk" do
    clear_users

    user = User.get("any_string")
    File.exists?(user.path).should be_false
    User.save_to_disk

    File.exists?(user.path).should be_true
    File.read(user.path).should eq("---\nmail: any_string\nlast_sync_time: 1970-01-01\nmapping: {}\nid_seed: \"\"\n")
  end

  it "should load users from disk" do
    clear_users

    File.write("/tmp/n2y-test/storage/user/load-user.yml", "---\nmail: load_user\nlast_sync_time: 1970-02-01\nmapping: {}\nid_seed: \"123\"\n")
    User.load_from_disk

    user = User.get("load-user")
    user.last_sync_time.should eq(Time.utc(1970, 2, 1))
    user.id_seed.should eq("123")
  end

  it "provides an YNAB TokenPair which saves on changes" do
    clear_users

    user = User.get("tokentest")
    user.ynab_token_pair.refresh?.should be_falsey
    user.ynab_token_pair.refresh = "refresh"

    User.load_from_disk
    user = User.get("tokentest")
    user.ynab_token_pair.refresh?.should eq("refresh")
  end

  it "stores account mapping" do
    clear_users
    mapping = {} of String => NamedTuple(id: String, budget_id: String)

    mapping["account1"] = {id: "id1", budget_id: "budget_id1"}
    mapping["account2"] = {id: "id2", budget_id: "budget_id2"}

    user = User.get("tokentest")

    user.mapping = mapping
    user.mapping.should eq(mapping)
    user.save

    User.load_from_disk
    user = User.get("tokentest")
    user.mapping.should eq(mapping)
  end

  it "migrates from database" do
    clear_users

    User.migrate
    user = User.get("existing-user@gmail.com").exists?.should be_true
    user = User.get("non-existing-user@gmail.com").exists?.should be_false
  end
end

require "./spec_helper"
require "../src/n2y/database"

describe "N2y::Db" do
  describe "#user?" do
    it "return nil for unknown users" do
      load_fixture "just-one-user"

      N2y::Db::INSTANCE.user?("test@gmail.com").should be_nil
    end

    it "return email for know users" do
      load_fixture "just-one-user"

      N2y::Db::INSTANCE.user?("existing-user@gmail.com").should eq "existing-user@gmail.com"
    end
  end

  describe "#add_user" do
    it "add user to database" do
      load_fixture "just-one-user"

      N2y::Db::INSTANCE.add_user("test2@gmail.com")

      N2y::Db::INSTANCE.user?("test2@gmail.com").should eq "test2@gmail.com"
    end

    it "throws if user already exists" do
      load_fixture "just-one-user"

      expect_raises(SQLite3::Exception) do
        N2y::Db::INSTANCE.add_user("existing-user@gmail.com")
      end
    end
  end
end

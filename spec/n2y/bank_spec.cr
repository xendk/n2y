require "../spec_helper"
require "../../src/n2y/bank"
require "json"

include N2y

class TestClient
  struct Account
    property :iban, :name

    def initialize(@iban : String, @name : String); end
  end

  getter accounts_calls = 0
  # Used to simulate changing account ids.
  @id_epoc = 0

  def change_ids
    @id_epoc += 1
  end

  def accounts(requisition_id : String)
    @accounts_calls += 1
    raise "bad requisition_id" unless requisition_id == "requisition_id"

    return {
      "123#{@id_epoc}" => Account.new("iban1", "name1"),
      "321#{@id_epoc}" => Account.new("iban2", "name2"),
    }
  end

  def transactions(account_id : String, *, from : Time? = nil, to : Time? = nil)
    # This should match the users last_sync_time.
    from.should eq Time.utc(2023, 4, 23, 17, 51, 54)

    case account_id
    when "123#{@id_epoc}"
      return [
        JSON.parse(%({"bookingDate":"2020-01-01","amount":1.0,"currency":"EUR"})),
      ]
    when "321#{@id_epoc}"
      return [] of JSON::Any
    else
      raise "bad account_id"
    end
  end
end

describe Bank do
  it "returns bank accounts for a user" do
    user = User.new("user")
    user.nordigen_requisition_id = "requisition_id"
    bank = Bank.new(user, TestClient.new)

    bank.accounts.should eq Hash{
      "iban1" => "name1",
      "iban2" => "name2",
    }
  end

  it "should raise on missing requisition id" do
    user = User.new("user")
    bank = Bank.new(user, TestClient.new)

    expect_raises(Bank::Error, "No requisition id") do
      bank.accounts
    end
  end

  it "catches and propagates errors" do
    user = User.new("user")
    user.nordigen_requisition_id = "bad_id"
    bank = Bank.new(user, TestClient.new)

    expect_raises(Bank::Error, "Failed to fetch bank accounts: bad requisition_id") do
      bank.accounts
    end
  end

  it "caches accounts" do
    user = User.new("user")
    user.nordigen_requisition_id = "requisition_id"
    client = TestClient.new
    bank = Bank.new(user, client)

    bank.accounts
    client.accounts_calls.should eq 1
    bank.accounts
    client.accounts_calls.should eq 1
  end

  it "fetches new transactions" do
    user = User.new("user")
    user.nordigen_requisition_id = "requisition_id"
    user.last_sync_time = Time.utc(2023, 4, 23, 17, 51, 54)
    client = TestClient.new
    bank = Bank.new(user, client)

    bank.new_transactions("iban1").should eq [JSON.parse(%({"bookingDate":"2020-01-01","amount":1.0,"currency":"EUR"}))]
    bank.new_transactions("iban2").should eq [] of JSON::Any
    client.accounts_calls.should eq 1
  end

  it "should refetch accounts when ids change" do
    user = User.new("user")
    user.nordigen_requisition_id = "requisition_id"
    user.last_sync_time = Time.utc(2023, 4, 23, 17, 51, 54)
    client = TestClient.new
    bank = Bank.new(user, client)

    bank.new_transactions("iban1").should eq [JSON.parse(%({"bookingDate":"2020-01-01","amount":1.0,"currency":"EUR"}))]
    client.change_ids
    bank.new_transactions("iban1").should eq [JSON.parse(%({"bookingDate":"2020-01-01","amount":1.0,"currency":"EUR"}))]

    client.accounts_calls.should eq 2
  end

  it "should return the same bank for the same user" do
    user = User.new("user")
    user.nordigen_requisition_id = "requisition_id"
    bank = Bank.for(user, TestClient)

    Bank.for(user, TestClient).should be bank
  end
end

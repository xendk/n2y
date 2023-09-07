require "../spec_helper"
require "../../src/n2y/budget"
require "../../src/n2y/ynab/account"
require "../../src/n2y/ynab/transaction"

include N2y

class TestClient
  # Log of pushed transactions.
  getter :_pushed
  @_pushed = [] of Tuple(String, Array(YNAB::Transaction))
  @_fail = false

  def initialize(token_pair : TokenPair); end

  def initialize(@_fail = false); end

  def accounts
    raise "bad stuff happened" if @_fail
    [
      YNAB::Account.new("account1", "name1", "budgetId1", "budgetName1"),
      YNAB::Account.new("account2", "name2", "budgetId2", "budgetName2"),
    ]
  end

  def push_transactions(budget_id : String, transactions : Array(YNAB::Transaction))
    @_pushed << {budget_id, transactions}
    0
  end
end

describe Budget do
  it "returns budget accounts for a user" do
    user = User.new("user")
    budget = Budget.new(user, TestClient.new)

    budget.accounts.should eq Hash{
      "account1" => "budgetName1 - name1",
      "account2" => "budgetName2 - name2",
    }
  end

  it "pushes transactions" do
    user = User.new("user")
    client = TestClient.new
    budget = Budget.new(user, client)

    set1 = [
      YNAB::Transaction.new(
        account_id: "account1",
        date: "2020-01-01",
        amount: 1000,
        payee_name: "payee",
        import_id: "imp1",
      ),
      YNAB::Transaction.new(
        account_id: "account1",
        date: "2020-01-01",
        amount: 1000,
        payee_name: "payee",
        import_id: "imp2",
      ),
    ]
    set2 = [
      YNAB::Transaction.new(
        account_id: "account2",
        date: "2020-01-01",
        amount: 1000,
        payee_name: "payee",
        import_id: "imp3",
      ),
    ]

    budget.push_transactions(set1 + set2).should eq 0

    client._pushed.size.should eq 2
    client._pushed[0][0].should eq "budgetId1"
    client._pushed[0][1].should eq set1
    client._pushed[1][0].should eq "budgetId2"
    client._pushed[1][1].should eq set2
  end

  it "catches and propagates errors" do
    user = User.new("user")
    budget = Budget.new(user, TestClient.new(true))

    expect_raises(Budget::Error, "Failed to fetch budget accounts: bad stuff happened") do
      budget.accounts
    end
  end

  it "should return the same budget for the same user" do
    user = User.new("user")
    budget = Budget.for(user, TestClient)

    Budget.for(user, TestClient).should be budget
  end
end

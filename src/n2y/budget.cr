require "./user"

module N2y
  module BudgetModule; end

  class Budget(ClientType)
    include BudgetModule

    class Error < Exception; end

    @@budgets = {} of User => BudgetModule
    @accounts = {} of String => NamedTuple(name: String, budget_id: String, budget_name: String)

    def self.for(user : User, klass : ClientType.class = YNAB)
      @@budgets[user] ||= new(user, klass.new(user.ynab_token_pair))
    end

    def initialize(@user : User, @client : ClientType); end

    # Get accounts as id => name.
    def accounts
      ensure_accounts
      @accounts.map { |id, account| {id, "#{account[:budget_name]} - #{account[:name]}"} }.to_h
    rescue ex
      raise Error.new("Failed to fetch budget accounts: #{ex.message || ex.class.to_s}", ex)
    end

    def push_transactions(transactions : Array(YNAB::Transaction))
      ensure_accounts

      budget_lookup = @accounts.map { |id, account|
        {id, account[:budget_id]}
      }.to_h

      skipped = 0
      transactions.chunks { |transaction|
        budget_lookup[transaction.account_id]
      }.each do |budget_id, budget_transactions|
        skipped += @client.push_transactions(budget_id, budget_transactions)
      end

      skipped
    rescue ex
      raise Error.new("Failed to push transactions: #{ex.message || ex.class.to_s}", ex)
    end

    protected def ensure_accounts
      return unless @accounts.empty?

      @accounts = @client.accounts.map { |account|
        {account.id, {
          name:        account.name,
          budget_id:   account.budget_id,
          budget_name: account.budget_name,
        }}
      }.to_h
    end
  end
end

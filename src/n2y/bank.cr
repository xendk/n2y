require "./user"

module N2y
  class Bank(ClientType)
    class Error < Exception; end

    record Account, iban : String, name : String

    @accounts = {} of String => Account

    def self.for(user : User, klass : ClientType.class = Nordigen)
      new(user, klass.new)
    end

    def initialize(@user : User, @client : ClientType); end

    protected def require_requisition
      requisition_id = @user.nordigen_requisition_id
      raise Error.new("No requisition id") unless requisition_id
      requisition_id
    end

    protected def ensure_accounts
      return unless @accounts.empty?
      requisition_id = require_requisition

      @accounts.clear

      @client.accounts(requisition_id).each do |id, account|
        @accounts[id] = Account.new(account.iban, account.name)
      end
    rescue ex
      raise Error.new("Failed to fetch bank accounts: #{ex.message || ex.class.to_s}", ex)
    end

    protected def with_account_refetch
      yield
    rescue ex
      @accounts.clear
      ensure_accounts
      yield
    end

    # Get accounts as IBAN => name.
    def accounts
      ensure_accounts
      accounts = {} of String => String

      @accounts.each do |id, account|
        accounts[account.iban] = account.name
      end

      accounts
    rescue ex
      raise Error.new("Failed to fetch bank accounts: #{ex.message || ex.class.to_s}", ex)
    end

    # Get new transactions for the given IBAN.
    def new_transactions(iban : String)
      requisition_id = require_requisition
      ensure_accounts

      with_account_refetch do
        account = @accounts.find { |id, account| account.iban == iban }

        raise Error.new("No account with IBAN #{iban}") unless account

        account_id, _ = account
        # We're not sending a to date to Nordigen, as it seems that at
        # least Danske Bank applies it to the "valueDate". On credit
        # accounts (at least in Danske Bank), the valueDate is in the
        # future (mostly the first bankday of next month), so
        # transactions wouldn't show up until then. Which would be very
        # confusing for the user as it's already booked when they look
        # in the bank, so the balance of the account wouldn't match
        # between Nordigen and YNAB.
        @client.transactions(account_id, from: @user.last_sync_time)
      end
    rescue ex
      raise Error.new("Failed to fetch transactions for #{iban}: #{ex.message || ex.class.to_s}", ex)
    end
  end
end

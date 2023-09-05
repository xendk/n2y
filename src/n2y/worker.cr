require "./user"
require "./nordigen"
require "./ynab"
require "./ynab/transaction"
require "./mapper"

module N2y
  # Worker for doing the syncing.
  class Worker
    def initialize(@user : User)
    end

    def run
      result = [] of String
      runtime = Time.utc

      raise "Cannot run on non-existent user" unless @user.exists?

      begin
        ynab = YNAB.new(@user.ynab_token_pair)
        duplicates = 0
        ynab_transactions = [] of YNAB::Transaction
        bank = Bank.for(@user)
        budget = Budget.for(@user)

        @user.mapping.each do |iban, mapping|
          transactions = bank.new_transactions(iban)
          # pass them through mapper
          transactions.each do |transaction|
            begin
              ynab_transactions << N2y::Mapper.map(transaction, mapping[:id], @user.id_seed)
            rescue ex
              message = "Failed to map transaction #{transaction.dig?("transactionId") || "<unknown>"} with error #{ex.message}"
              result << message
              N2y::User::Log.error { message }
              log_exception(ex)
            end
          end
        end

        if ynab_transactions.size > 0
          duplicates = budget.push_transactions(ynab_transactions)
          message = "Synced #{ynab_transactions.size} transactions, #{duplicates} already existed"
        else
          message = "No new transactions to sync"
        end

        result << message
        User::Log.info { message }
        # update user last sync date
        @user.last_sync_time = runtime
        @user.save
      rescue ex : N2y::Nordigen::ConnectionError
        message = "Error communicating with bank, please try again later"

        result << message
        N2y::User::Log.error { message }
      rescue ex
        message = "Failed to sync transactions: #{ex.message}"
        result << message
        N2y::User::Log.error { message }
        log_exception(ex)
      end

      result
    end
  end
end

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
        count = 0
        duplicates = 0
        ynab_transactions = {} of String => Array(YNAB::Transaction)
        bank = Bank.for(@user)

        @user.mapping.each do |iban, mapping|
          budget_id = mapping[:budget_id]
          transactions = bank.new_transactions(iban)
          ynab_transactions[budget_id] ||= [] of YNAB::Transaction
          # pass them through mapper
          transactions.each do |transaction|
            begin
              ynab_transaction = N2y::Mapper.map(transaction, budget_id, mapping[:id], @user.id_seed)
              ynab_transactions[budget_id] << ynab_transaction if ynab_transaction
            rescue ex
              message = "Failed to map transaction #{transaction.dig?("transactionId") || "<unknown>"} with error #{ex.message}"
              result << message
              N2y::User::Log.error { message }
              log_exception(ex)
            end
          end
        end

        ynab_transactions.each do |budget_id, transactions|
          count += transactions.size
          duplicates += ynab.push_transactions(budget_id, transactions) unless transactions.size.zero?
        end

        message = "Synced #{count} transactions, #{duplicates} already existed"
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

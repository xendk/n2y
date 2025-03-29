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
      raise "Cannot run on non-existent user" unless @user.exists?

      begin
        ynab = YNAB.new(@user.ynab_token_pair)
        duplicates = 0
        ynab_transactions = [] of YNAB::Transaction
        bank = Bank.for(@user)
        budget = Budget.for(@user)

        @user.account_mapping.each do |iban, account_id|
          begin
            transactions = bank.new_transactions(iban)

            transactions.each do |transaction|
              begin
                ynab_transactions << N2y::Mapper.map(transaction, account_id, @user.id_seed)
              rescue ex
                N2y::User::Log.error { "Failed to map transaction #{transaction.dig?("transactionId") || "<unknown>"} with error #{ex.message}" }
                log_exception(ex, @user)
              end
            end
          rescue ex : N2y::Bank::UnknownAccount
            N2y::User::Log.error { "Unknown account #{iban}, skipping" }
          end
        end

        if ynab_transactions.size > 0
          duplicates = budget.push_transactions(ynab_transactions)
          User::Log.info { "Synced #{ynab_transactions.size} transactions, #{duplicates} already existed" }
        else
          User::Log.info { "No new transactions to sync" }
        end

      rescue ex : N2y::Nordigen::ConnectionError
        N2y::User::Log.error { "Error communicating with bank, please try again later" }
      rescue ex
        N2y::User::Log.error { "Failed to sync transactions: #{ex.message}" }
        log_exception(ex, @user)
      end
    end
  end
end

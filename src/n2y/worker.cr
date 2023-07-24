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
        accounts = N2y::Nordigen.new.accounts(@user.nordigen_requisition_id.as(String))

        ynab_transactions = {} of String => Array(YNAB::Transaction)
        accounts.each do |id, account|
          next unless @user.mapping.has_key?(account.iban)

          budget_id = @user.mapping[account.iban][:budget_id]

          # We're not sending a to date to Nordigen, as it seems that
          # at least Danske Bank applies it to the "valueDate". On
          # credit accounts (at least in Danske Bank), the valueDate
          # is in the future (mostly the first bankday of next month),
          # so transactions wouldn't show up until then.
          transactions = N2y::Nordigen.new.transactions(id, from: @user.last_sync_time)
          ynab_transactions[budget_id] ||= [] of YNAB::Transaction
          # pass them through mapper
          transactions.each do |transaction|
            begin
              ynab_transaction = N2y::Mapper.map(transaction, budget_id, @user.mapping[account.iban][:id], @user.id_seed)
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

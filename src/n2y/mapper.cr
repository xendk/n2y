require "./ynab/transaction"
require "digest/sha1"

module N2y
  module Mapper
    def self.map(data : JSON::Any, budget_id : String, account_id : String, id_seed = "") : N2y::YNAB::Transaction?
      booking_date = data.dig?("bookingDate").try &.as_s
      raise "No booking date in transaction" unless booking_date
      raise "Invalid booking date: #{booking_date}" unless booking_date =~ /^\d{4}-\d{2}-\d{2}$/

      transaction_id = data.dig?("transactionId").try &.as_s
      raise "No transaction id in transaction" unless transaction_id

      import_id = (booking_date + Digest::SHA1.new.update(id_seed).update(transaction_id).hexfinal)[0..35]

      payee_name = data.dig?("remittanceInformationUnstructured").try &.as_s.split("\n", 2).first
      payee_name = data.dig?("additionalInformation").try &.as_s unless payee_name
      raise "No additionalInformation nor remittanceInformationUnstructured in transaction" unless payee_name

      # Nordigen seems to return the amount as a string.
      amount = data.dig?("transactionAmount", "amount").try { |x| (x.as_s.to_f * 1000).to_i }
      raise "No amount in transaction" unless amount
      # raise "Transaction in future" if

      YNAB::Transaction.new(
        budget_id: budget_id,
        account_id: account_id,
        date: booking_date,
        amount: amount,
        payee_name: payee_name,
        import_id: import_id,
      )
    end
  end
end

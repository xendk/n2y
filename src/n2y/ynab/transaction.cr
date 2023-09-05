module N2y
  class YNAB
    # Transaction to send to YNAB.
    class Transaction
      include JSON::Serializable

      property account_id : String?
      property date : String?
      # Amount in milliunits format.
      property amount : Int32?
      property payee_name : String?
      property cleared = "cleared"
      property import_id : String?

      def_equals :account_id, :date, :amount, :payee_name, :import_id

      def initialize(*, account_id : String? = nil, date : String? = nil, amount : Int32? = nil, payee_name : String? = nil, import_id : String? = nil)
        @account_id = account_id
        @date = date
        @amount = amount
        @payee_name = payee_name
        @import_id = import_id
      end

      def valid?
        @account_id && @date && @amount && @payee_name && @import_id
      end
    end
  end
end

# Response classes for YNAB.
#
# This is a bit messy due to the YNAB API insisting on returinig
# everything with a top-level "data" key, which is a bit redundant.

module N2y
  class YNAB
    class YNABObject
      include JSON::Serializable

      class Error < YNABObject
        getter name : String
        getter detail : String
      end

      class BudgetData < YNABObject
        getter budgets : Array(Budget)
      end

      class Budget < YNABObject
        getter id : String
        getter name : String
        getter accounts : Array(Account)
      end

      class Account < YNABObject
        getter id : String
        getter name : String
      end
    end

    class TransactionsData < YNABObject
      getter duplicate_import_ids : Array(String)
    end

    class Response < YNABObject
    end

    class AuthorizeResponse < Response
      getter access_token : String
      getter refresh_token : String
    end

    class ErrorResponse < Response
      getter error : Error
    end

    class BudgetsResponse < Response
      getter data : BudgetData
    end

    class TransactionsResponse < Response
      getter data : TransactionsData
    end

    alias Responses = Response | Array(Response)
  end
end

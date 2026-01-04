# Response classes for YNAB.
#
# This is a bit messy due to the YNAB API insisting on returinig
# everything with a top-level "data" key, which is a bit redundant.

module N2y
  class YNAB
    # YNAB data transfer objects.
    #
    # YNAB DTOs subclasses are defined within this class namespace.
    # This brings them in scope for any class subclassing the DTO
    # class.
    class DTO
      include JSON::Serializable

      class Error < DTO
        getter name : String
        getter detail : String
      end

      class BudgetData < DTO
        getter budgets : Array(Budget)
      end

      class Budget < DTO
        getter id : String
        getter name : String
        getter accounts : Array(Account)
      end

      class Account < DTO
        getter id : String
        getter name : String
        getter deleted : Bool
      end

      class TransactionsData < DTO
        getter duplicate_import_ids : Array(String)
      end
    end

    class Response < DTO
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

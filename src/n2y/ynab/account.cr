module N2y
  class YNAB
    class Account
      getter id : String
      getter name : String
      getter budget_id : String
      getter budget_name : String

      def_equals id, name, budget_id, budget_name

      def initialize(@id, @name, @budget_id, @budget_name)
      end
    end
  end
end

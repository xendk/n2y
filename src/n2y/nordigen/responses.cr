# Response classes for Nordigen.

module N2y
  class Nordigen
    class Response
      include JSON::Serializable
    end

    class RefreshTokenResponse < Response
      getter access : String
      getter access_expires : Int32
    end

    class TokenResponse < RefreshTokenResponse
      getter refresh : String
      getter refresh_expires : Int32
    end

    class Bank < Response
      getter id : String
      getter name : String
      getter logo : String

      def initialize(@id, @name, @logo)
      end
    end

    class RequisitionResponse < Response
      getter id : String
      getter redirect : String
      getter reference : String
      getter link : String
    end

    alias Responses = Response | Array(Response)
  end
end

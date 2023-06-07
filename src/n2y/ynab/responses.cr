# Response classes for YNAB.

module N2y
  class YNAB
    class Response
      include JSON::Serializable
    end

    class AuthorizeResponse < Response
      getter access_token : String
      getter refresh_token : String
    end

    alias Responses = Response | Array(Response)
  end
end

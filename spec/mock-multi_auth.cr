# MultiAuth mock for testing
#
# Always returns a user, so calling /auth/callback will always succeed.
module MultiAuth
  @@email : String?

  def self.email=(@@email)
  end

  def self.email
    @@email
  end

  def self.make(provider, redirect_uri)
    return FakeEngine.new()
  end

  class FakeEngine
    def authorize_uri(scope = nil)
      "http://somewhere.at/google"
    end

    def user(params : Enumerable({String, String}))
      user = MultiAuth::User.new(
        "fakeprovider",
        "123456789",
        "test-user",
        "{}"
      )

      user.email = MultiAuth.email
      user
    end
  end

  # Overload user to make OAuth token optional (they're difficult to create).
  class User
    @access_token : ((OAuth2::AccessToken | OAuth::AccessToken))?

    def initialize(@provider, @uid, @name, @raw_json)
    end
  end
end

# Run authentication and returns the headers to keep the session.
def authenticate(email)
  MultiAuth.email = email
  # Auth endpoints needs the host header to construct the callback url.
  get "/auth/callback", HTTP::Headers{"Host" => "localhost"}

  response.status_code.should eq 302

  response.headers["Location"].should eq "/"

  cookie = response.headers["Set-Cookie"].split(';').first

  HTTP::Headers{"Cookie" => cookie}
end

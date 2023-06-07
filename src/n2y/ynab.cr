require "../n2y"
require "uri"
require "json"
require "http/client"
require "habitat"
require "./ynab/*"

module N2y
  class YNAB
    Habitat.create do
      setting client_id : String
      setting secret : String
    end

    getter access_token : String?
    getter refresh_token : String?

    @oauth_base_uri = URI.parse("https://app.ynab.com/oauth/")

    @headers = HTTP::Headers {
      "Accept" => "application/json",
      "Content-Type" => "application/json",
      "User-Agent" => "N2y",
    }

    def initialize()
    end

    # Get the URI to redirect the user to for authorization.
    def redirect_uri(return_uri : URI)
      redirect_uri = @oauth_base_uri.resolve(URI.parse("authorize"))
      redirect_uri.query = URI::Params.encode({
        "client_id" => settings.client_id,
        "redirect_uri" => return_uri.to_s,
        "response_type" => "code",
      })
      redirect_uri
    end

    def redirect_uri(return_uri : String)
      redirect_uri(URI.parse(return_uri))
    end

    # Authorize the code returned from the redirect.
    def authorize(code : String, return_uri : URI)
      uri = @oauth_base_uri.resolve(URI.parse("token"))
      uri.query = URI::Params.encode({
        "client_id" => settings.client_id,
        "client_secret" => settings.secret,
        "redirect_uri" => return_uri.to_s,
        "grant_type" => "authorization_code",
        "code" => code,
      })
      response = HTTP::Client.post(uri, headers: @headers, body: "")
      if response.success?
        res = AuthorizeResponse.from_json(response.body)
        @access_token = res.access_token
        @refresh_token = res.refresh_token
      else
        raise "Failed to authorize: #{response.body}"
      end
    end
  end
end

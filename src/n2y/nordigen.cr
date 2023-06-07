require "../n2y"
require "uri"
require "json"
require "http/client"
require "http/headers"
require "habitat"
require "./nordigen/*"

module N2y
  class Nordigen
    Habitat.create do
      setting secret_id : String
      setting secret : String
    end

    property access_token : String | Nil
    property refresh_token : String | Nil

    DENIED_MAPPING = {
      "/api/v2/token/refresh/" => InvalidRefreshToken,
      "/api/v2/token/new/" => InvalidCreds,
    }

    def initialize()
      @base_uri = URI.parse("https://ob.nordigen.com/api/v2/")
      @headers = HTTP::Headers {
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "User-Agent" => "N2y",
      }
    end

    # Returns known banks.
    def get_banks(lang : String)
      get("institutions", query: {"country" => lang}, class: Array(Bank))
    end

    # Make a GET request at Nordigen.
    def get(path : String, *, data = nil, query = nil, class klass : Responses.class)
      request("GET", path, query: query, data: data, class: klass)
    end

    # Make a POST request at Nordigen.
    def post(path : String, *, data = nil, query = nil, class klass : Responses.class)
      request("POST", path, query: query, data: data, class: klass)
    end

    # Make request to Nordigen.
    def request(method : String, path : String, *, query = nil, data = nil, class klass : Responses.class)
      path = URI.parse(path)
      path.query = URI::Params.encode(query) if query
      data = data.try &.to_json || ""
      begin
        do_request(method, path, data: data, class: klass)
      rescue ex : InvalidAccessToken | InvalidRefreshToken
        @access_token = nil
        if ex.is_a? InvalidRefreshToken
          @refresh_token = nil
        end
        refresh_tokens
        do_request(method, path, data: data, class: klass)
      end
    end

    # Refreshes tokens.
    #
    # Uses refresh_token if one is available, or secret_id/secret to
    # obtain a access/refresh pair.
    protected def refresh_tokens
      if @refresh_token
        data = {
          "refresh" => @refresh_token,
        }.to_json

        response = do_request("POST", URI.parse("token/refresh"), data: data, class: RefreshTokenResponse)
      else
        data = {
          "secret_id" => settings.secret_id,
          "secret_key" => settings.secret,
        }.to_json

        response = do_request("POST", URI.parse("token/new"), data: data, class: TokenResponse)
      end
      @refresh_token = response.refresh if response.is_a? TokenResponse
      @access_token = response.access
    end

    # Do request.
    protected def do_request(method : String, path : URI, *, data : String, class klass : Responses.class)
      headers = @headers
      path = @base_uri.resolve(path)
      # For some reason Nordigen insists that all it's endpoint ends
      # in a slash, and returns a redirect if one forgets.
      path.path = path.path + "/"
      if @access_token
        headers["Authorization"] = "Bearer #{@access_token}"
      end
      response = HTTP::Client.exec(method, path, headers: headers, body: data)
      handle_status_codes path, response
      klass.from_json(response.body)
    end

    # Thows the appropiate exception if *response* has a non-success
    # status code.
    protected def handle_status_codes(uri, response)
      if !response.success?
        raise (DENIED_MAPPING[uri.path]? || InvalidAccessToken).new if response.status_code == 401
        raise "IP blacklisted" if response.status_code == 403
        raise "Ratelimit hit" if response.status_code == 429
        raise "Got redirect to #{response.headers["Location"]} on #{uri.path}" if response.status_code == 301

        raise "Unexpected response #{response.status_code} code \"#{response.status_message}\", body: #{response.body}"
      end
    end
  end
end

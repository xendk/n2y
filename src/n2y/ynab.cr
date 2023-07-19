require "../n2y"
require "uri"
require "json"
require "http/client"
require "habitat"
require "./ynab/*"
require "./token_pair"

module N2y
  class YNAB
    Habitat.create do
      setting client_id : String
      setting secret : String
    end

    @base_uri = URI.parse("https://api.ynab.com/v1/")
    @oauth_base_uri = URI.parse("https://app.ynab.com/oauth/")

    @headers = HTTP::Headers {
      "Accept" => "application/json",
      "Content-Type" => "application/json",
      "User-Agent" => "N2y",
    }

    def initialize(@token_pair : N2y::TokenPair)
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
      do_refresh({
        "grant_type" => "authorization_code",
        "redirect_uri" => return_uri.to_s,
        "code" => code,
      }, "Failed to authorize")
    end

    protected def refresh_tokens
      do_refresh({
        "grant_type" => "refresh_token",
        "refresh_token" => @token_pair.refresh,
      }, "Failed to refresh tokens")
    end

    protected def do_refresh(params : Hash(String, String), error_message : String)
      uri = @oauth_base_uri.resolve(URI.parse("token"))
      uri.query = URI::Params.encode({
        "client_id" => settings.client_id,
        "client_secret" => settings.secret,
      }.merge(params))
      response = HTTP::Client.post(uri, headers: @headers, body: "")
      if response.success?
        res = AuthorizeResponse.from_json(response.body)
        @token_pair.access = res.access_token
        @token_pair.refresh = res.refresh_token
      else
        raise "#{error_message}: #{response.body}"
      end
    end

    def accounts : Array(Account)
      res = request("GET", "budgets", query: {"include_accounts" => "true"}, class: BudgetsResponse)
      accounts = [] of Account
      res.data.budgets.each do |budget|
        budget.accounts.each do |account|
          accounts << Account.new(account.id, account.name, budget.id, budget.name)
        end
      end

      accounts
    end

    # Push transactions to YNAB, and return the number of duplicated transactions.
    def push_transactions(budget_id : String, transactions : Array(Transaction))
      res = request("POST", "budgets/#{budget_id}/transactions", data: {
                      "transactions" => transactions
                    }, class: TransactionsResponse)

      res.data.duplicate_import_ids.size
    end

    # Make request to YNAB. Possibly refreshing tokens if needed.
    def request(method : String, path : String, *, query = nil, data = nil, class klass : Responses.class)
      path = URI.parse(path)
      path.query = URI::Params.encode(query) if query

      data = data.try &.to_json || ""

      headers = @headers.dup

      tries = 2
      #response : HTTP::Client::Response
      while tries > 0
        begin
          headers["Authorization"] = "Bearer #{@token_pair.access}" if @token_pair.access?

          response = handle_error_response(HTTP::Client.exec(method, @base_uri.resolve(path), headers: headers, body: data))
          break
        rescue ex : AuthException
          if tries == 2
            @token_pair.invalidate_access
            refresh_tokens
          elsif tries == 1
            @token_pair.invalidate
            raise ex
          end
          tries -= 1
        end
      end

      klass.from_json(response.as(HTTP::Client::Response).body)
    end

    def handle_error_response(response)
      if response.success?
        response
      else
        begin
          error_response = ErrorResponse.from_json(response.body)
        rescue
          raise "Failed to parse error response: #{response.body}"
        end
        raise response.status_code == 401 ? AuthException.new(error_response.error.detail) :
                                                               error_response.error.detail
      end
    end
  end
end

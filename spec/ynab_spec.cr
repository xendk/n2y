require "./spec_helper"
require "../src/n2y/ynab"
require "../src/n2y/token_pair"
require "webmock"

example_uri = URI.parse("https://example.com/")

include N2y

YNAB.configure do |settings|
  settings.client_id = "client_id"
  settings.secret = "secret"
end

class DummyResponse < YNAB::Response
  getter dummy : String
end

token_expected_headers = HTTP::Headers{"Accept" => "application/json", "Content-Type" => "application/json", "User-Agent" => "N2y"}
expected_headers = token_expected_headers.dup.add("Authorization", "Bearer access_token")

describe YNAB do
  it "provides a redirect URI" do
    YNAB.new(TokenPair.new).redirect_uri(example_uri)
      .should eq(URI.parse("https://app.ynab.com/oauth/authorize?client_id=client_id&redirect_uri=https%3A%2F%2Fexample.com%2F&response_type=code"))
  end

  it "fetches tokens when provided an authorization code" do
    WebMock.stub(:post, "https://app.ynab.com/oauth/token?client_id=client_id&client_secret=secret&redirect_uri=https%3A%2F%2Fexample.com%2F&grant_type=authorization_code&code=123").
      with(body: "", headers: token_expected_headers).
      to_return(body: "{\"access_token\":\"access_token\",\"token_type\":\"bearer\",\"expires_in\":7200,\"refresh_token\":\"refresh_token\"}")

    token_pair = TokenPair.new
    ynab = YNAB.new(token_pair)
    ynab.authorize("123", example_uri)
    token_pair.access.should eq("access_token")
    token_pair.refresh.should eq("refresh_token")
  end

  describe "#request" do
    it "should retry when token expires" do
      WebMock.stub(:post, "https://app.ynab.com/oauth/token?client_id=client_id&client_secret=secret&grant_type=refresh_token&refresh_token=refresh_token")
        .with(body: "", headers: token_expected_headers)
        .to_return(body: "{\"access_token\":\"access_token2\",\"token_type\":\"bearer\",\"expires_in\":7200,\"refresh_token\":\"refresh_token2\"}")

      WebMock.stub(:get, "https://api.ynab.com/v1/random")
        .with(body: "", headers: expected_headers)
        .to_return(status: 401, body: "{\"error\":{\"id\":\"401\",\"name\":\"unauthorized\",\"detail\":\"Unauthorized\"}}")

      WebMock.stub(:get, "https://api.ynab.com/v1/random")
        .with(body: "", headers: {"Accept" => "application/json", "Content-Type" => "application/json", "User-Agent" => "N2y", "Authorization" => "Bearer access_token2"})
        .to_return(body: "{\"dummy\": \"dummy_val\"}")


      token_pair = TokenPair.new(access: "access_token", refresh: "refresh_token")
      ynab = YNAB.new(token_pair)

      ynab.request("GET", "random", class: DummyResponse).dummy.should eq("dummy_val")
      token_pair.access.should eq("access_token2")
      token_pair.refresh.should eq("refresh_token2")
    end
  end

  it "gets accounts" do
    WebMock.stub(:get, "https://api.ynab.com/v1/budgets?include_accounts=true").
      with(headers: expected_headers).
      to_return(body: "{\"data\":{\"budgets\":[{\"id\":\"1\",\"name\":\"Budget 1\",\"accounts\":[{\"id\":\"12\",\"name\":\"Checking\"},{\"id\":\"22\",\"name\":\"Savings\"}]},{\"id\":\"2\",\"name\":\"Budget 2\",\"accounts\":[{\"id\":\"21\",\"name\":\"Cayman\"}]}]}}")

    token_pair = TokenPair.new(access: "access_token", refresh: "refresh_token")
    ynab = YNAB.new(token_pair)

    expected = [
      YNAB::Account.new("12", "Checking", "1", "Budget 1"),
      YNAB::Account.new("22", "Savings", "1", "Budget 1"),
      YNAB::Account.new("21", "Cayman", "2", "Budget 2"),
    ]
    ynab.accounts.should eq(expected)
  end
end

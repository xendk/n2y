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

describe YNAB do
  it "provides a redirect URI" do
    YNAB.new(TokenPair.new).redirect_uri(example_uri)
      .should eq(URI.parse("https://app.ynab.com/oauth/authorize?client_id=client_id&redirect_uri=https%3A%2F%2Fexample.com%2F&response_type=code"))
  end

  it "fetches tokens when provided an authorization code" do
    WebMock.stub(:post, "https://app.ynab.com/oauth/token?client_id=client_id&client_secret=secret&redirect_uri=https%3A%2F%2Fexample.com%2F&grant_type=authorization_code&code=123").
      with(body: "", headers: {"Accept" => "application/json", "Content-Type" => "application/json", "User-Agent" => "N2y"}).
      to_return(body: "{\"access_token\":\"access_token\",\"token_type\":\"bearer\",\"expires_in\":7200,\"refresh_token\":\"refresh_token\"}")

    token_pair = TokenPair.new
    ynab = YNAB.new(token_pair)
    ynab.authorize("123", example_uri)
    token_pair.access.should eq("access_token")
    token_pair.refresh.should eq("refresh_token")
  end
end

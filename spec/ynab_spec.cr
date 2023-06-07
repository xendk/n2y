require "./spec_helper"
require "../src/n2y/ynab"
require "webmock"

example_uri = URI.parse("https://example.com/")

N2y::YNAB.configure do |settings|
  settings.client_id = "client_id"
  settings.secret = "secret"
end

describe "N2y::YNAB" do
  it "provides a redirect URI" do
    N2y::YNAB.new().redirect_uri(example_uri)
      .should eq(URI.parse("https://app.ynab.com/oauth/authorize?client_id=client_id&redirect_uri=https%3A%2F%2Fexample.com%2F&response_type=code"))
  end

  it "fetches tokens when provided an authorization code" do
    WebMock.stub(:post, "https://app.ynab.com/oauth/token?client_id=client_id&client_secret=secret&redirect_uri=https%3A%2F%2Fexample.com%2F&grant_type=authorization_code&code=123").
      with(body: "", headers: {"Accept" => "application/json", "Content-Type" => "application/json", "User-Agent" => "N2y"}).
      to_return(body: "{\"access_token\":\"access_token\",\"token_type\":\"bearer\",\"expires_in\":7200,\"refresh_token\":\"refresh_token\"}")

    ynab = N2y::YNAB.new()
    ynab.authorize("123", example_uri)
    ynab.access_token.should eq("access_token")
    ynab.refresh_token.should eq("refresh_token")
  end
end

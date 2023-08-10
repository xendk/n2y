require "../spec_helper"
require "../../src/n2y/nordigen"
require "../../src/n2y/token_pair"
require "http/headers"

include N2y

Nordigen.configure do |settings|
  settings.secret_id = "secret_id"
  settings.secret = "secret"
end

class Nordigen::DummyResponse < Nordigen::Response
  getter dummy : String
end

api_root = "https://bankaccountdata.gocardless.com/api/v2/"
token_expected_headers = HTTP::Headers{"Accept" => "application/json", "Content-Type" => "application/json", "User-Agent" => "N2y"}
expected_headers = token_expected_headers.dup.add("Authorization", "Bearer access_token")

Spec.before_each do
  WebMock.reset
end

describe Nordigen do
  it "fetches tokens when none available" do
    WebMock.stub(:post, api_root + "token/new/")
      .with(body: "{\"secret_id\":\"secret_id\",\"secret_key\":\"secret\"}", headers: token_expected_headers)
      .to_return(body: "{\"access\": \"access_token\",\"access_expires\": 86400,\"refresh\": \"refresh_token\",\"refresh_expires\": 2592000}")

    WebMock.stub(:get, api_root + "random_endpoint/")
      .with(body: "", headers: token_expected_headers)
      .to_return do |request|
      if request.headers["Authorization"]? != "Bearer access_token"
        HTTP::Client::Response.new(401, body: "Access denied")
      else
        HTTP::Client::Response.new(200, body: "{\"dummy\": \"data\"}")
      end
    end

    token_pair = TokenPair.new()
    nordigen = Nordigen.new(token_pair)

    nordigen.get("random_endpoint", class: Nordigen::DummyResponse).dummy.should eq("data")

    token_pair.refresh.should eq("refresh_token")
    token_pair.access.should eq("access_token")
  end

  it "uses refresh token when available" do
    WebMock.stub(:post, api_root + "token/refresh/")
      .with(body: "{\"refresh\":\"the_refresh_token\"}", headers: token_expected_headers)
      .to_return(body: "{\"access\": \"new_access_token\",\"access_expires\": 86400}")

    WebMock.stub(:get, api_root + "random_endpoint/")
      .with(body: "", headers: token_expected_headers)
      .to_return do |request|
      if request.headers["Authorization"]? != "Bearer new_access_token"
        HTTP::Client::Response.new(401, body: "Access denied")
      else
        HTTP::Client::Response.new(200, body: "{\"dummy\": \"data\"}")
      end
    end

    token_pair = TokenPair.new(refresh: "the_refresh_token")
    nordigen = Nordigen.new(token_pair)

    nordigen.get("random_endpoint", class: Nordigen::DummyResponse).dummy.should eq("data")

    token_pair.refresh.should eq("the_refresh_token")
    token_pair.access.should eq("new_access_token")
  end

  it "throws on invalid creds" do
    WebMock.stub(:post, api_root + "token/new/")
      .to_return(status: 401)
    WebMock.stub(:get, api_root + "random_endpoint/")
      .with(body: "", headers: token_expected_headers)
      .to_return(status: 401)

    nordigen = Nordigen.new()

    expect_raises(Exception, message: "Invalid secret_id/secret") do
      nordigen.get("random_endpoint", class: Nordigen::DummyResponse)
    end
  end

  it "throws on invalid refresh token" do
    WebMock.stub(:post, api_root + "token/refresh/")
      .with(body: "{\"refresh\":\"the_refresh_token\"}", headers: token_expected_headers)
      .to_return(status: 401)
    WebMock.stub(:get, api_root + "random_endpoint/")
      .with(body: "", headers: token_expected_headers)
      .to_return(status: 401)

    token_pair = TokenPair.new(refresh: "the_refresh_token")
    nordigen = Nordigen.new(token_pair)

    expect_raises(Exception, message: "Invalid or expired refresh token") do
      nordigen.get("random_endpoint", class: Nordigen::DummyResponse)
    end

    # Refresh token should be invalidated.
    token_pair.refresh?.should be_falsey
  end

  it "#get returns requested class" do
    nordigen = Nordigen.new(TokenPair.new(access: "access_token"))

    WebMock.stub(:get, api_root + "random_endpoint/").
      with(body: "", headers: token_expected_headers).
      to_return(body: "{\"dummy\": \"data\"}")

    nordigen.get("random_endpoint", class: Nordigen::DummyResponse).dummy.should eq("data")
  end

  it "returns a list of banks" do
    nordigen = Nordigen.new(TokenPair.new(access: "access_token"))

    WebMock.stub(:get, api_root + "institutions/?country=DK")
      .with(headers: expected_headers)
      .to_return(body: "[{\"id\":\"BANK1\",\"name\":\"Bank 1\",\"countries\":[\"DK\"],\"logo\":\"1...\"},{\"id\":\"BANK2\",\"name\":\"Bank 2\",\"countries\":[\"DK\"],\"logo\":\"2...\"}]")

    banks = nordigen.get_banks("DK")
    banks.should be_a Array(Nordigen::Bank)
    banks.size.should eq 2

    banks[0].id.should eq "BANK1"
    banks[0].name.should eq "Bank 1"
    banks[0].logo.should eq "1..."

    banks[1].id.should eq "BANK2"
    banks[1].name.should eq "Bank 2"
    banks[1].logo.should eq "2..."
  end

  it "can request a requisition" do
    nordigen = Nordigen.new(TokenPair.new(access: "access_token"))

    WebMock.stub(:post, api_root + "requisitions/")
      .with(body: "{\"redirect\":\"https://google.com\",\"institution_id\":\"MYBANK\",\"reference\":\"userreference\",\"user_language\":\"DA\"}", headers: expected_headers)
      # Not a full response, but what we care about.
      .to_return(body: "{\"id\":\"123\",\"redirect\":\"https://google.com\",\"reference\":\"userreference\",\"user_language\":\"DA\",\"link\":\"https://magicurlatgocardless.com/something\"}")

    requisition_id, redirect_uri = nordigen.create_requisition("MYBANK", URI.parse("https://google.com"), "userreference")

    requisition_id.should eq "123"
    redirect_uri.should eq URI.parse("https://magicurlatgocardless.com/something")
  end

  it "can fetch accounts with a requisition" do
    nordigen = Nordigen.new(TokenPair.new(access: "access_token"))

    # Not full responses, but what we care about.
    WebMock.stub(:get, api_root + "requisitions/123/")
      .with(headers: expected_headers)
      .to_return(body: "{\"accounts\":[\"a1\",\"a2\"]}")

    WebMock.stub(:get, api_root + "accounts/a1/details/")
      .with(headers: expected_headers)
      .to_return(body: "{\"account\":{\"iban\":\"iban1\",\"name\":\"name1\"}}")

    WebMock.stub(:get, api_root + "accounts/a2/details/")
      .with(headers: expected_headers)
      .to_return(body: "{\"account\":{\"iban\":\"iban2\",\"name\":\"name2\"}}")

    accounts = nordigen.accounts("123")

    accounts.should be_a Hash(String, Nordigen::Account)
    accounts.size.should eq 2

    accounts["a1"].iban.should eq "iban1"
    accounts["a1"].name.should eq "name1"

    accounts["a2"].iban.should eq "iban2"
    accounts["a2"].name.should eq "name2"
  end

  it "can fetch account transactions" do
    nordigen = Nordigen.new(TokenPair.new(access: "access_token"))

    # Fictional response, we're just checking that it returns the
    # content of the "booked" key as JSON::Any.
    WebMock.stub(:get, api_root + "accounts/123/transactions/")
      .with(headers: expected_headers)
      .to_return(body: "{\"transactions\":{\"booked\":[{\"id\":\"1\",\"name\":\"one\"},{\"id\":\"2\",\"name\":\"two\"}],\"pending\":[{\"id\":\"3\",\"name\":\"three\"}]}}")

    transactions = nordigen.transactions("123")

    transactions.should be_a Array(JSON::Any)
    transactions.size.should eq 2

    transactions[0]["id"].as_s.should eq "1"
    transactions[0]["name"].as_s.should eq "one"

    transactions[1]["id"].as_s.should eq "2"
    transactions[1]["name"].as_s.should eq "two"
  end
end

require "./spec_helper"
require "../src/n2y/nordigen"
require "webmock"
require "http/headers"

class DummyResponse < N2y::Nordigen::Response
  getter dummy : String
end

token_expected_headers = HTTP::Headers{"Accept" => "application/json", "Content-Type" => "application/json", "User-Agent" => "N2y"}
expected_headers = token_expected_headers.dup.add("Authorization", "Bearer access_token")

Spec.before_each do
  WebMock.reset
end

describe "N2y::Nordigen" do
  it "fetches tokens when none available" do
    WebMock.stub(:post, "https://ob.nordigen.com/api/v2/token/new/")
      .with(body: "{\"secret_id\":\"secret_id\",\"secret_key\":\"secret\"}", headers: token_expected_headers)
      .to_return(body: "{\"access\": \"access_token\",\"access_expires\": 86400,\"refresh\": \"refresh_token\",\"refresh_expires\": 2592000}")

    WebMock.stub(:get, "https://ob.nordigen.com/api/v2/random_endpoint/")
      .with(body: "", headers: token_expected_headers)
      .to_return do |request|
      if request.headers["Authorization"]? != "Bearer access_token"
        HTTP::Client::Response.new(401, body: "Access denied")
      else
        HTTP::Client::Response.new(200, body: "{\"dummy\": \"data\"}")
      end
    end

    nordigen = N2y::Nordigen.new("secret_id", "secret")

    nordigen.get("random_endpoint", class: DummyResponse).dummy.should eq("data")

    nordigen.refresh_token.should eq("refresh_token")
    nordigen.access_token.should eq("access_token")
  end

  it "fetches uses refresh token when available" do
    WebMock.stub(:post, "https://ob.nordigen.com/api/v2/token/refresh/")
      .with(body: "{\"refresh\":\"the_refresh_token\"}", headers: token_expected_headers)
      .to_return(body: "{\"access\": \"new_access_token\",\"access_expires\": 86400}")

    WebMock.stub(:get, "https://ob.nordigen.com/api/v2/random_endpoint/")
      .with(body: "", headers: token_expected_headers)
      .to_return do |request|
      if request.headers["Authorization"]? != "Bearer new_access_token"
        HTTP::Client::Response.new(401, body: "Access denied")
      else
        HTTP::Client::Response.new(200, body: "{\"dummy\": \"data\"}")
      end
    end

    nordigen = N2y::Nordigen.new("secret_id", "secret_key")

    nordigen.refresh_token = "the_refresh_token"

    nordigen.get("random_endpoint", class: DummyResponse).dummy.should eq("data")

    nordigen.refresh_token.should eq("the_refresh_token")
    nordigen.access_token.should eq("new_access_token")
  end

  it "throws on invalid creds" do
    WebMock.stub(:post, "https://ob.nordigen.com/api/v2/token/new/")
      .to_return(status: 401)
    WebMock.stub(:get, "https://ob.nordigen.com/api/v2/random_endpoint/")
      .with(body: "", headers: token_expected_headers)
      .to_return(status: 401)

    nordigen = N2y::Nordigen.new("secret_id", "secret_key")

    expect_raises(Exception, message: "Invalid secret_id/secret") do
      nordigen.get("random_endpoint", class: DummyResponse)
    end
  end

  it "throws on invalid refresh token" do
    WebMock.stub(:post, "https://ob.nordigen.com/api/v2/token/refresh/")
      .with(body: "{\"refresh\":\"the_refresh_token\"}", headers: token_expected_headers)
      .to_return(status: 401)
    WebMock.stub(:get, "https://ob.nordigen.com/api/v2/random_endpoint/")
      .with(body: "", headers: token_expected_headers)
      .to_return(status: 401)

    nordigen = N2y::Nordigen.new("secret_id", "secret_key")

    nordigen.refresh_token = "the_refresh_token"

    expect_raises(Exception, message: "Invalid or expired refresh token") do
      nordigen.get("random_endpoint", class: DummyResponse)
    end
  end

  it "#get returns requested class" do
    nordigen = N2y::Nordigen.new("secret_id", "secret_key")
    nordigen.access_token = "access_token"

    WebMock.stub(:get, "https://ob.nordigen.com/api/v2/random_endpoint/").
      with(body: "", headers: token_expected_headers).
      to_return(body: "{\"dummy\": \"data\"}")

    nordigen.get("random_endpoint", class: DummyResponse).dummy.should eq("data")
  end

  it "returns a list of banks" do
    nordigen = N2y::Nordigen.new("secret_id", "secret_key")
    nordigen.access_token = "access_token"

    WebMock.stub(:get, "https://ob.nordigen.com/api/v2/institutions/?country=DK")
      .with(headers: expected_headers)
      .to_return(body: "[{\"id\":\"BANK1\",\"name\":\"Bank 1\",\"countries\":[\"DK\"],\"logo\":\"1...\"},{\"id\":\"BANK2\",\"name\":\"Bank 2\",\"countries\":[\"DK\"],\"logo\":\"2...\"}]")

    banks = nordigen.get_banks("DK")
    banks.should be_a Array(N2y::Nordigen::Bank)
    banks.size.should eq 2

    banks[0].id.should eq "BANK1"
    banks[0].name.should eq "Bank 1"
    banks[0].logo.should eq "1..."

    banks[1].id.should eq "BANK2"
    banks[1].name.should eq "Bank 2"
    banks[1].logo.should eq "2..."
  end
end

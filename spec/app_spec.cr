require "./spec_helper"
require "spec-kemal"
require "../src/n2y/app"
# Use a mock of MultiAuth that'll always return a user when we hit
# /auth/callback.
require "./mock-multi_auth"

load_fixture("just-one-user")

describe N2y::App do
  it "redirects to /auth when unauthenticated" do
    get "/"

    response.status_code.should eq 302
    response.headers["Location"].should eq "/auth"
  end

  it "renders front page when authenticated" do
    get "/", authenticate

    response.status_code.should eq 200
    response.body.should contain "N2Y"
  end

  it "presents new users with the Terms of Service page" do
    get "/", authenticate("test@gmail.com")

    response.status_code.should eq 302
    response.headers["Location"].should eq "/auth/tos"
  end

  it "allows for creating a new user by accepting the terms of service" do
    session = authenticate("test@gmail.com")
    get "/", session

    session["Content-Type"] = "application/x-www-form-urlencoded"
    post "/auth/tos", session, HTTP::Params.encode({"accepted": "1"})

    N2y::Db::INSTANCE.user?("test@gmail.com").should eq "test@gmail.com"
  end

  it "not accepting reloads the terms of service" do
    session = authenticate("test2@gmail.com")
    get "/", session

    session["Content-Type"] = "application/x-www-form-urlencoded"
    post "/auth/tos", session, HTTP::Params.encode({} of String => String)

    response.status_code.should eq 302
    response.headers["Location"].should eq "/auth/tos"
    N2y::Db::INSTANCE.user?("test2@gmail.com").should eq nil
  end
end

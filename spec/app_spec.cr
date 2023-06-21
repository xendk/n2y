require "./spec_helper"
require "spec-kemal"
require "../src/n2y/app"
require "../src/n2y/nordigen"
require "../src/n2y/ynab"
# Use a mock of MultiAuth that'll always return a user when we hit
# /auth/callback.
require "./mock-multi_auth"

Kemal::Session.config do |config|
  config.cookie_name = "n2y_session_id"
  config.secret = ENV["SESSION_SECRET"]? || raise "SESSION_SECRET not set"
  config.gc_interval = 2.minutes # 2 minutes
end

# Use the same fixture for all the tests. They should be safe to run
# on the same database.
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
    session = authenticate("test2@gmail.com")
    get "/", session

    session["Content-Type"] = "application/x-www-form-urlencoded"
    post "/auth/tos", session, HTTP::Params.encode({"accepted": "1"})

    N2y::User.get("test2@gmail.com").exists?.should eq true
  end

  it "not accepting reloads the terms of service" do
    session = authenticate("test3@gmail.com")
    get "/", session

    session["Content-Type"] = "application/x-www-form-urlencoded"
    post "/auth/tos", session, HTTP::Params.encode({} of String => String)

    response.status_code.should eq 302
    response.headers["Location"].should eq "/auth/tos"
    N2y::User.get("test3@gmail.com").exists?.should eq false
  end
end

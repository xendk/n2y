require "../spec_helper"
require "spec-kemal"
require "../../src/n2y/app"
require "../../src/n2y/nordigen"
require "../../src/n2y/ynab"
require "../../src/n2y/rotating_backend"
# Use a mock of MultiAuth that'll always return a user when we hit
# /auth/callback.
require "../mock-multi_auth"
require "timecop"

Kemal::Session.config do |config|
  config.cookie_name = "n2y_session_id"
  config.secret = ENV["SESSION_SECRET"]? || raise "SESSION_SECRET not set"
  config.gc_interval = 2.minutes # 2 minutes
end

Kemal.run

describe N2y::App do
  it "redirects to /auth when unauthenticated" do
    get "/"

    response.status_code.should eq 302
    response.headers["Location"].should eq "/auth"
  end

  it "renders front page when authenticated" do
    clear_users
    user = N2y::User.get("existing-user@gmail.com")
    user.tos_accepted_time = Time.utc
    user.save

    get "/", authenticate("existing-user@gmail.com")

    response.status_code.should eq 200
    response.body.should contain "N2Y"
  end

  it "times out sessions after a while" do
    clear_users
    user = N2y::User.get("existing-user@gmail.com")
    user.tos_accepted_time = Time.utc
    user.save
    time = Time.local

    Timecop.travel(time) do
      N2y::User.get("existing-user@gmail.com").save
      headers = authenticate("existing-user@gmail.com")
      get "/", headers

      response.status_code.should eq 200
      response.body.should contain "N2Y"

      Timecop.travel(time + 8.days)
      get "/", headers

      response.status_code.should eq 302
      response.headers["Location"].should eq "/auth"
    end
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

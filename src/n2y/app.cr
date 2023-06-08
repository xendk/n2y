require "multi_auth"
require "kemal-session"

module N2y::App
  # Render a view in the default layout.
  macro render_page(template)
    render "src/views/#{ {{template}} }.ecr", "src/views/layout.ecr"
  end
end

require "./app/*"

module N2y
  Kemal::Session.config do |config|
    config.cookie_name = "n2y_session_id"
    config.secret = "super-secret"
    config.secret = ENV["SESSION_SECRET"]? || raise "SESSION_SECRET not set"
    config.gc_interval = 2.minutes # 2 minutes
  end
add_context_storage_type(N2y::User)

  module App
    # Adds UTF-8 charset to HTML responses.
    class ContentTypeHandler < Kemal::Handler
      def call(context)
        context.response.content_type = "text/html;charset=UTF-8" if context.response.headers["Content-Type"] == "text/html"
        call_next context
      end
    end

    add_handler ContentTypeHandler.new

    static_headers do |response, filepath, filestat|
      # Don't cache responses.
      response.headers["Cache-Control"] = "no-store"
      # Tell robots to go away.
      response.headers["X-Robots-Tag"] = "noindex"
    end

    get "/" do |env|
      title = "Home"
      user = (env.get "user").as(N2y::User)
      render_page "index"
    end

    get "/privacy-policy" do |env|
      title = "Privacy Policy"
      N2y::App.render_page "privacy-policy"
    end

    # Throw an error for testing purposes.
    get "/kaboom" do |env|
      raise "Oh noooes! (Relax, this is just a test)"
    end

    Kemal.run
  end
end

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
    config.cookie_name = "session_id"
    config.secret = "super-secret"
    config.gc_interval = 2.minutes # 2 minutes
  end

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
      render_page "index"
    end

    # Throw an error for testing purposes.
    get "/kaboom" do |env|
      raise "Oh noooes! (Relax, this is just a test)"
    end

    Kemal.run
  end
end

# Authentication related code for the web app.
module N2y::App::Auth
  # Kemal middleware for authentication.
  #
  # Redirects to login page if user is not authenticated, and new
  # users to terms of service.
  class Handler < Kemal::Handler
    exclude [
      "/favicon.ico",
      "/privacy-policy",
      "/auth",
      "/auth/callback",
      "/auth/tos",
      "/auth/logout",
      "/auth/error",
      "/kaboom"
    ]
    exclude ["/auth/tos"], "POST"

    def call(context)
      context.session.string?("user_id")
      return call_next(context) if exclude_match?(context)

      if context.session.string?("user_id")
        if N2y::Db::INSTANCE.user?(context.session.string?("user_id"))
          call_next(context)
        else
          # New users have to accept the terms of service. We don't
          # add them to the user list until they do.
          context.redirect "/auth/tos"
        end
      else
        context.redirect "/auth"
      end
    end
  end

  add_handler N2y::App::Auth::Handler.new

  # Start authentication by redirecting to Google.
  get "/auth" do |env|
    redirect_uri = "#{Kemal.config.scheme}://#{env.request.headers["Host"]}/auth/callback"

    env.redirect(MultiAuth.make("google", redirect_uri).authorize_uri)
  end

  # Return callback.
  get "/auth/callback" do |env|
    redirect_uri = "#{Kemal.config.scheme}://#{env.request.headers["Host"]}/auth/callback"

    user = MultiAuth.make("google", redirect_uri).user(env.params.query)

    mail = user.email

    if mail
      env.session.string("user_id", mail)

      env.redirect "/"
    else
      env.redirect "/auth/error"
    end
  end

  # Show terms of service.
  get "/auth/tos" do |env|
    title = "Terms of Service"
    N2y::App.render_page "tos"
  end

  # Accept terms of service.
  post "/auth/tos" do |env|
    accepted = env.params.body["accepted"]? && env.params.body["accepted"]?.as(String) == "1"

    if accepted
      N2y::Db::INSTANCE.add_user(env.session.string?("user_id"))
      env.redirect "/"
    else
      env.redirect "/auth/tos"
    end
  end

  # Error page displayed when we don't get a good callback from Google.
  get "/auth/error" do |env|
    title = "Authentication Error"
    content = "Error authenticating with Google. Please try again."
    render "src/views/layout.ecr"
  end
end

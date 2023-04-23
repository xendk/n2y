# Authentication related code for the web app.
module N2y::App::Auth
  # Kemal middleware for authentication.
  #
  # Redirects to login page if user is not authenticated, and new
  # users to EULA.
  class Handler < Kemal::Handler
    exclude ["/favicon.ico", "/auth", "/auth/callback", "/auth/eula", "/auth/logout", "/auth/error", "/kaboom"]
    exclude ["/auth/eula"], "POST"

    def call(context)
      context.session.string?("user_id")
      return call_next(context) if exclude_match?(context)

      if context.session.string?("user_id")
        if N2y::Db::INSTANCE.user?(context.session.string?("user_id"))
          call_next(context)
        else
          # New users have to accept the EULA. We don't add them to
          # the user list until they do.
          context.redirect "/auth/eula"
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

  # Show EULA.
  get "/auth/eula" do |env|
    title = "End User License Agreement"
    N2y::App.render_page "eula"
  end

  # Accept EULA.
  post "/auth/eula" do |env|
    accepted = env.params.body["accepted"]? && env.params.body["accepted"]?.as(String) == "1"

    if accepted
      N2y::Db::INSTANCE.add_user(env.session.string?("user_id"))
      env.redirect "/"
    else
      env.redirect "/auth/eula"
    end
  end

  # Error page displayed when we don't get a good callback from Google.
  get "/auth/error" do |env|
    title = "Authentication Error"
    content = "Error authenticating with Google. Please try again."
    render "src/views/layout.ecr"
  end
end

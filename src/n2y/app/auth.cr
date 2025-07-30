# Authentication related code for the web app.
module N2y::App::Auth
  excluded_get = [
    "/favicon.ico",
    "/privacy-policy",
    "/tos",
    "/auth",
    "/auth/callback",
    "/auth/tos",
    "/auth/logout",
    "/auth/error",
    "/kaboom",
  ]
  excluded_post = [
    "/auth/tos",
  ]

  # Kemal middleware for authentication.
  #
  # Redirects to login page if user is not authenticated, and sets up
  # user logging.
  class AuthHandler < Kemal::Handler
    exclude excluded_get
    exclude excluded_post, "POST"

    def call(env)
      return call_next(env) if exclude_match?(env)

      if env.session.string?("user_id")
        user = N2y::User.get(env.session.string("user_id"))

        env.set "user", user
        N2y::User::Log.context.set user_id: env.session.string("user_id")
        call_next(env)
      else
        # Tell HTMX that this redirect shouldn't be displayed inline.
        if env.request.headers["HX-Request"]?
          env.response.headers["HX-Location"] = "/auth"
          ""
        else
          env.redirect "/auth"
        end
      end
    end
  end

  # Logout users after a week. At login is the only time we get
  # Googles word that this browser is actually the user, so we'll
  # check up on it occasionally.
  class LoginTimeoutHandler < Kemal::Handler
    exclude excluded_get
    exclude excluded_post, "POST"

    def call(env)
      return call_next(env) if exclude_match?(env)

      user = (env.get "user").as(N2y::User)

      if (user.login_time + 7.days) < Time.utc
        if env.request.headers["HX-Request"]?
          env.response.headers["HX-Location"] = "/auth"
          ""
        else
          env.redirect "/auth"
        end
      else
        call_next(env)
      end
    end
  end

  # Redirect new users to terms of service.
  class TosHandler < Kemal::Handler
    exclude excluded_get
    exclude excluded_post, "POST"

    def call(env)
      return call_next(env) if exclude_match?(env)

      user = (env.get "user").as(N2y::User)

      # if (user.last_login_time + 7.days) < Time.utc
      # end

      if user.tos_accepted_time
        call_next(env)
      else
        env.redirect "/auth/tos"
      end
    end
  end

  Kemal.config.add_handler N2y::App::Auth::AuthHandler.new
  Kemal.config.add_handler N2y::App::Auth::LoginTimeoutHandler.new
  Kemal.config.add_handler N2y::App::Auth::TosHandler.new

  # Start authentication by redirecting to Google.
  get "/auth" do |env|
    title = "About"
    redirect_uri = "#{Kemal.config.scheme}://#{env.request.headers["Host"]}/auth/callback"

    redirect_uri = MultiAuth.make("google", redirect_uri).authorize_uri

    App.render_page "about"
  end

  # Return callback.
  get "/auth/callback" do |env|
    redirect_uri = "#{Kemal.config.scheme}://#{env.request.headers["Host"]}/auth/callback"

    mail : String?

    # Seems that some bots hits this page without a code.
    unless env.params.query["code"]?
      env.redirect "/auth/error"
      next
    end

    begin
      user = MultiAuth.make("google", redirect_uri).user(env.params.query)
      mail = user.email
    rescue ex
      log_exception(ex)
    end

    if mail
      env.session.string("user_id", mail.downcase.strip)

      user = N2y::User.get(env.session.string("user_id"))
      user.login_time = Time.utc

      N2y::User::Log.context.set user_id: env.session.string("user_id")
      N2y::User::Log.info { "Logged in" }

      env.redirect "/"
    else
      env.redirect "/auth/error"
    end
  end

  # Accept terms of service page.
  get "/auth/tos" do |env|
    title = "Terms of Service"
    tos = render "src/views/tos.ecr"
    N2y::App.render_page "tos_page"
  end

  # Accept terms of service.
  post "/auth/tos" do |env|
    accepted = env.params.body["accepted"]? && env.params.body["accepted"]?.as(String) == "1"

    if accepted && env.session.string?("user_id")
      user = N2y::User.get(env.session.string("user_id"))
      user.tos_accepted_time = Time.utc
      user.save
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

  # Select a bank to authenticate with.
  get "/auth/nordigen/select_bank" do |env|
    title = "Select Bank"
    banks = Nordigen.new.get_banks "DK"
    N2y::App.render_page "select_bank"
  end

  # Start authentication with Nordigen with selected bank.
  get "/auth/nordigen/:bank_id" do |env|
    bank_id = env.params.url["bank_id"].as(String)
    redirect_uri = "#{Kemal.config.scheme}://#{env.request.headers["Host"]}/auth/nordigen/callback"

    user = (env.get "user").as(N2y::User)
    # Generate reference from mail and current time in miliseconds.
    # Current time in seconds ought to be enough (there's really not a
    # use case for more than one authentication per second), but it's
    # just one more char when base62 encoded, so why not.
    requisition_id, url = N2y::Nordigen.new.create_requisition(
      bank_id,
      URI.parse(redirect_uri),
      "#{user.mail}-#{Time.utc.to_unix_ms.to_s(62)}"
    )
    env.session.string("nordigen_requisition_id", requisition_id)

    env.redirect url
  end

  # Callback from Nordigen.
  get "/auth/nordigen/callback" do |env|
    user = (env.get "user").as(N2y::User)

    user.nordigen_requisition_id = env.session.string("nordigen_requisition_id")
    N2y::User::Log.info { "Authenticated with Nordigen" }

    user.save

    env.redirect "/"
  rescue ex
    # TODO: Something link `env.error_page = "/auth/ynab/error"` seems nicer.
    log_exception(ex)
    env.redirect "/auth/nordigen/error"
  end

  # Error page displayed when we don't get a good callback from YNAB.
  get "/auth/nordigen/error" do |env|
    title = "Authentication Error"
    content = "Error authenticating with Nordigen. Please try again."
    render "src/views/layout.ecr"
  end

  # Redirect to YNAB for authentication.
  get "/auth/ynab" do |env|
    redirect_uri = "#{Kemal.config.scheme}://#{env.request.headers["Host"]}/auth/ynab/callback"

    user = (env.get "user").as(N2y::User)

    env.redirect(N2y::YNAB.new(user.ynab_token_pair).redirect_uri(redirect_uri))
  end

  # Callback from YNAB.
  get "/auth/ynab/callback" do |env|
    code = env.params.query["code"].as(String)

    user = (env.get "user").as(N2y::User)

    N2y::YNAB.new(user.ynab_token_pair).authorize(code, URI.parse("#{Kemal.config.scheme}://#{env.request.headers["Host"]}/auth/ynab/callback"))
    N2y::User::Log.info { "Authenticated with YNAB" }

    env.redirect "/"
  rescue ex
    # TODO: Something link `env.error_page = "/auth/ynab/error"` seems nicer.
    log_exception(ex)
    env.redirect "/auth/ynab/error"
  end

  # Error page displayed when we don't get a good callback from YNAB.
  get "/auth/ynab/error" do |env|
    title = "Authentication Error"
    content = "Error authenticating with YNAB. Please try again."
    render "src/views/layout.ecr"
  end
end

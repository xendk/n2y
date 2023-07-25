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
      "/tos",
      "/auth",
      "/auth/callback",
      "/auth/tos",
      "/auth/logout",
      "/auth/error",
      "/kaboom",
    ]
    exclude ["/auth/tos"], "POST"

    def call(context)
      return call_next(context) if exclude_match?(context)

      if context.session.string?("user_id")
        user = N2y::User.get(context.session.string("user_id"))
        if user.exists?
          context.set "user", user
          N2y::User::Log.context.set user_id: context.session.string("user_id")
          call_next(context)
        else
          # New users have to accept the terms of service. We don't
          # add them to the user list until they do.
          context.redirect "/auth/tos"
        end
      else
        # Tell HTMX that this redirect shouldn't be displayed inline.
        if context.request.headers["HX-Request"]?
          context.response.headers["HX-Location"] = "/auth"
          ""
        else
          context.redirect "/auth"
        end
      end
    end
  end

  Kemal.config.add_handler N2y::App::Auth::Handler.new

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

    begin
      user = MultiAuth.make("google", redirect_uri).user(env.params.query)
      mail = user.email
    rescue ex
        log_exception(ex)
    end

    if mail
      env.session.string("user_id", mail)

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
      N2y::User.get(env.session.string("user_id")).save
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

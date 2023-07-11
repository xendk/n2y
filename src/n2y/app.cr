require "multi_auth"
require "kemal-session"
require "./ext/*"

module N2y::App
  # Render a view in the default layout.
  macro render_page(template)
    render "src/views/#{ {{template}} }.ecr", "src/views/layout.ecr"
  end
end

require "./app/*"

add_context_storage_type(N2y::User)

module N2y
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

    get "/mapping" do |env|
      title = "Mapping"
      render_page "mapping_page"
    end

    get "/mapping/form" do |env|
      user = (env.get "user").as(N2y::User)
      error : String?

      nordigen_accounts = [] of Nordigen::Account
      ynab_accounts = [] of YNAB::Account

      begin
        nordigen_accounts = N2y::Nordigen.new.accounts(user.nordigen_requisition_id.as(String))
      rescue ex
        error = "Failed to fetch accounts from Nordigen: " + (ex.message || ex.class.to_s)
        N2y::User::Log.error { error }
      end

      unless error
        begin
           ynab_accounts = N2y::YNAB.new(user.ynab_token_pair).accounts
        rescue ex
          error = "Failed to fetch accounts from YNAB" + (ex.message || ex.class.to_s)
          N2y::User::Log.error { error }
        end
      end

      options = {} of String => String

      ynab_accounts.each do |ynab_account|
        options[ynab_account.id + "|" + ynab_account.budget_id] = ynab_account.budget_name + ": " + ynab_account.name
      end

      mapping = {} of String => String
      Hash(String, NamedTuple(id: String, budget_id: String)).from_json(user.mapping).each do |key, value|
        mapping[key] = value[:id] + "|" + value[:budget_id]
      end

      if error
        render "src/views/mapping_error.ecr"
      else
        render "src/views/mapping.ecr"
      end
    end

    post "/mapping/save" do |env|
      user = (env.get "user").as(N2y::User)
      # accounts = env.params.body["mapping"].as(Array)

      mapping = {} of String => NamedTuple(id: String, budget_id: String)

      env.params.body.each do |key, value|
        key = key[/mapping\[(.+)\]/, 1]?
        next unless key

        value.split('|', 2).tap do |ids|
          next unless ids.size == 2
          mapping[key] = {id: ids[0], budget_id: ids[1]}
        end
      end

      user.mapping = mapping.to_json
      user.save
      env.redirect "/"
    end

    get "/log" do |env|
      title = "Log"
      user = (env.get "user").as(N2y::User)
      entries = user.log_entries
      render_page "log"
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

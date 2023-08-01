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
require "./worker"

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
      nordigen_connected : Bool = !!user.nordigen_requisition_id
      ynab_connected : Bool = !!user.ynab_token_pair.usable?
      sync_time : String? = user.last_sync_time ? user.last_sync_time.to_s : nil
      render_page "index"
    end

    get "/mapping" do |env|
      title = "Mapping"
      render_page "mapping_page"
    end

    get "/mapping/form" do |env|
      user = (env.get "user").as(N2y::User)
      error : String?

      nordigen_accounts = {} of String => Nordigen::Account
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
      user.mapping.each do |key, value|
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
      mapping = {} of String => NamedTuple(id: String, budget_id: String)

      env.params.body.each do |key, value|
        key = key[/mapping\[(.+)\]/, 1]?
        next unless key

        value.split('|', 2).tap do |ids|
          next unless ids.size == 2
          mapping[key] = {id: ids[0], budget_id: ids[1]}
        end
      end

      user.mapping = mapping
      user.id_seed = env.params.body["id_seed"].as(String)
      begin
        user.last_sync_time = Time.parse_utc(env.params.body["last_sync_time"].as(String), "%F")
      rescue ex
        # Simply ignore bad user data for the moment being.
      end
      user.save
      env.redirect "/"
    end

    get "/log" do |env|
      title = "Log"
      user = (env.get "user").as(N2y::User)
      log_dir = File.join(N2y::RotatingBackend.settings.storage_path, user.mail)

      entries = [] of {timestamp: String, severity: String, message: String, data: String?}

      if File.exists? log_dir
        Dir[File.join(log_dir, "*.log")].sort.each do |log_file|
          File.open(File.join(log_file), "r") do |file|
            file.each_line do |line|
              line = line.chomp
              next if line.empty?
              parts = line.split('\t', 4)
              next if parts.size < 3
              time, severity, message = parts
              data = parts[3]?
              entries << {timestamp: time, severity: severity, message: message, data: data}
            end
          end
        end
      end

      entries.reverse!
      render_page "log"
    end

    get "/sync" do |env|
      user = (env.get "user").as(N2y::User)
      worker = N2y::Worker.new user
      worker.run.join("<br/>")
    end

    get "/privacy-policy" do |env|
      title = "Privacy Policy"
      render_page "privacy-policy"
    end

    # Show terms of service.
    get "/tos" do |env|
      title = "Terms of Service"
      render_page "tos"
    end

    # Throw an error for testing purposes.
    get "/kaboom" do |env|
      raise "Oh noooes! (Relax, this is just a test)"
    end
  end
end

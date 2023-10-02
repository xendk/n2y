require "../n2y"
require "yaml"
require "habitat"
require "log"
require "./token_pair"

module N2y
  class User
    include YAML::Serializable

    Log = ::Log.for(self)

    Habitat.create do
      setting storage_path : String
    end

    @@users = {} of String => User

    getter mail : String
    property login_time : Time = Time.unix(0)
    property tos_accepted_time : Time?
    property nordigen_requisition_id : String?
    property ynab_refresh_token : String?
    property last_sync_time : Time = Time.unix(0)
    property sync_interval : Int32 = 0
    property mapping = {} of String => NamedTuple(id: String, budget_id: String)
    setter account_mapping = {} of String => String
    property id_seed = ""

    @[YAML::Field(ignore: true)]
    @token_pair : TokenPair?

    def self.load_from_disk
      @@users = {} of String => User
      Dir.glob(File.join(settings.storage_path, "*.yml")) do |path|
        mail = File.basename(path, ".yml")
        @@users[mail] = User.from_yaml(File.read(path))
      end
    end

    def self.save_to_disk
      @@users.each_value do |user|
        user.save
      end
    end

    def self.get(mail : String)
      @@users[mail] ||= User.new(mail)
    end

    def self.all
      @@users.values
    end

    def initialize(@mail : String)
    end

    def path
      File.join(settings.storage_path, "#{@mail}.yml")
    end

    def exists?
      File.exists?(path)
    end

    def save
      File.write(path, to_yaml)
    end

    def account_mapping
      if @account_mapping.empty?
        @mapping.each do |key, value|
          @account_mapping[key] = value[:id]
        end
      end

      @account_mapping
    end

    def ynab_token_pair
      @token_pair ||= TokenPair.new(refresh: ynab_refresh_token) do |token|
        if @ynab_refresh_token != token.refresh?
          @ynab_refresh_token = token.refresh
          save
        end
      end
    end
  end
end

require "dotenv"

Dotenv.load

require "yaml"
require "./n2y/nordigen"

# Add YAML::Serializable so we can prettyprint the objects.
class N2y::Nordigen::Bank
  include YAML::Serializable
end

secret_id = ENV["NORDIGEN_SECRET_ID"]? || raise "NORDIGEN_SECRET_ID not set"
secret = ENV["NORDIGEN_SECRET"]? || raise "NORDIGEN_SECRET not set"

nordigen = N2y::Nordigen.new(secret_id, secret)

puts nordigen.get_banks("DK").to_yaml

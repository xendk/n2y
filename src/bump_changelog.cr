require "semantic_version"

# Read the CHANGELOG.md file and bump the version number, and add a
# new "Unreleased" section. Outputs the previously unreleased version
# number to stdout.
begin
  buffer = IO::Memory.new

  version = nil : String?

  File.open("CHANGELOG.md", "r") do |file|
    while line = file.gets(false)
      if line =~ /^## ([0-9\.]+) - Unreleased/
        version = $1
        next_version = SemanticVersion.parse(version).bump_patch

        buffer << "## #{next_version} - Unreleased\n\n"

        buffer << "## #{version} - #{Time.utc.to_s("%Y-%m-%d")}\n"
      else
        buffer << line
      end
    end
  end

  if version.nil?
    raise "Could not find next version in CHANGELOG.md"
  end

  puts version
  File.open("CHANGELOG.md", "w") do |file|
    file << buffer
  end
rescue ex
  puts ex
  exit 1
end

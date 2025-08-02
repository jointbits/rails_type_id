# frozen_string_literal: true

require_relative "lib/rails_type_id/version"

Gem::Specification.new do |spec|
  spec.name = "rails_type_id"
  spec.version = RailsTypeId::VERSION
  spec.authors = ["Franklin Hu"]
  spec.email = ["franklin@thisisfranklin.com"]

  spec.summary = "TypeID primary keys for ActiveRecord models"
  spec.description = <<~DESCRIPTION
    rails_type_id is a gem that makes it simple to use TypeIDs
    as the primary key for ActiveRecord models.
  DESCRIPTION
  spec.homepage = "https://github.com/jointbits/rails_type_id"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "rails", "~> 8.0.2"
  spec.add_dependency "sorbet-runtime"
  spec.add_dependency "typeid", "~> 0.2.2"
end

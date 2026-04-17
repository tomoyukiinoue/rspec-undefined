# frozen_string_literal: true

require_relative "lib/rspec/undefined/version"

Gem::Specification.new do |spec|
  spec.name = "rspec-undefined"
  spec.version = RSpec::Undefined::VERSION
  spec.authors = ["Tomoyuki INOUE"]

  spec.summary = "RSpec extension to explicitly express 'undefined specification' in tests"
  spec.description = "Provides matchers and DSL to explicitly record undefined values and behaviors " \
                     "in tests, designed for extracting specifications from legacy systems."
  spec.homepage = "https://github.com/tomoyukiinoue/rspec-undefined"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0").map { |f| f.chomp("\x0") }.reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "rspec-core", ">= 3.0", "< 4"
  # csv is available as stdlib/bundled gem in Ruby 2.0-3.3.
  # The gem version requires Ruby >= 2.5, so it is not included in gemspec.
  # If csv is removed from bundled gems in Ruby 3.4+, add it in the Gemfile.
end

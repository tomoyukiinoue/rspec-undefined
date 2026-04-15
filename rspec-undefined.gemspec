# frozen_string_literal: true

require_relative "lib/rspec/undefined/version"

Gem::Specification.new do |spec|
  spec.name = "rspec-undefined"
  spec.version = RSpec::Undefined::VERSION
  spec.authors = ["Tomoyuki INOUE"]
  spec.email = ["tomoyuki.inoue@gmail.com"]

  spec.summary = "「仕様が未確定」であることをテスト内で明示的に表現する RSpec 拡張"
  spec.description = "レガシーシステムから現行踏襲仕様を起こすために、未確定の値や振る舞いを " \
                     "テスト中で明示的に記録できるマッチャと DSL を提供する。"
  spec.homepage = "https://github.com/tomoyukiinoue/rspec-undefined"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0").map { |f| f.chomp("\x0") }.reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rspec-core", ">= 3.0", "< 4"
  spec.add_dependency "csv"
end

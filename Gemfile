# frozen_string_literal: true

source "https://rubygems.org"

gemspec

if RUBY_VERSION >= "2.2"
  gem "rake", "~> 13.0"
else
  gem "rake", "~> 12.0"
end

gem "rspec", "~> 3.0"

# csv は Ruby 3.1 以降では bundled gem のため明示的に追加
gem "csv" if RUBY_VERSION >= "3.1"

if RUBY_VERSION >= "2.7"
  gem "irb"
  gem "rubocop", "~> 1.21"
end

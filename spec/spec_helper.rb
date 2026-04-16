# frozen_string_literal: true

require "rspec/undefined"
require "tempfile"

# Polyfill Tempfile.create for Ruby 2.0 (introduced in 2.1)
unless Tempfile.respond_to?(:create)
  def Tempfile.create(basename = "", tmpdir = nil, mode: 0, **options)
    tmpfile = new(basename, tmpdir, mode: mode, **options)
    path = tmpfile.path
    tmpfile.close
    if block_given?
      begin
        yield File.open(path, "r+")
      ensure
        File.unlink(path) if File.exist?(path)
      end
    else
      path
    end
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

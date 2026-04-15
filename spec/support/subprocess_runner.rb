# frozen_string_literal: true

require "open3"
require "tempfile"

module SubprocessRunner
  # spec ソース文字列を一時ファイルに書き、rspec を別プロセスで実行する
  def run_spec_source(source, env: {})
    Tempfile.create(["dsl_spec", ".rb"]) do |f|
      f.write(<<~RUBY + source)
        $LOAD_PATH.unshift(File.expand_path("#{Dir.pwd}/lib"))
        require "rspec/autorun"
        require "rspec/undefined/configuration"
        require "rspec/undefined/entry"
        require "rspec/undefined/registry"
        require "rspec/undefined/matchers"
        require "rspec/undefined/dsl"

        module RSpec
          module Undefined
            class << self
              def registry
                Registry.instance
              end
              def configuration
                @configuration ||= Configuration.new
              end
              def configure
                yield configuration
              end
            end
          end
        end

        RSpec.configure do |c|
          c.include RSpec::Undefined::Matchers
        end
      RUBY
      f.flush
      cmd = ["bundle", "exec", "rspec", f.path, "--format", "documentation"]
      stdout, stderr, status = Open3.capture3(env, *cmd)
      [stdout, stderr, status]
    end
  end
end

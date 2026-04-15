# frozen_string_literal: true

require "open3"
require "tempfile"

module SubprocessRunner
  def run_spec_source(source, env: {})
    Tempfile.create(["dsl_spec", ".rb"]) do |f|
      f.write(<<~RUBY + source)
        $LOAD_PATH.unshift(File.expand_path("#{Dir.pwd}/lib"))
        require "rspec/autorun"
        require "rspec/undefined"
      RUBY
      f.flush
      cmd = ["bundle", "exec", "rspec", f.path, "--format", "documentation"]
      stdout, stderr, status = Open3.capture3(env, *cmd)
      [stdout, stderr, status]
    end
  end
end

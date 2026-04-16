# frozen_string_literal: true

require "rspec/core"
require "rspec/undefined/version"
require "rspec/undefined/configuration"
require "rspec/undefined/categories"
require "rspec/undefined/entry"
require "rspec/undefined/registry"
require "rspec/undefined/matchers"
require "rspec/undefined/dsl"
require "rspec/undefined/formatter"
require "rspec/undefined/sentinels"
require "rspec/undefined/reporters/json"
require "rspec/undefined/reporters/yaml"
require "rspec/undefined/reporters/markdown"

module RSpec
  module Undefined
    class Error < StandardError; end
  end
end

RSpec.configure do |rspec|
  rspec.include RSpec::Undefined::Matchers

  rspec.before(:suite) do
    RSpec::Undefined.registry.clear
  end

  rspec.after(:suite) do
    io = $stdout
    RSpec::Undefined::Formatter.new(io).dump_summary(nil)

    cfg = RSpec::Undefined.configuration
    if cfg.report_path
      reporter =
        case cfg.report_format
        when :json then RSpec::Undefined::Reporters::Json.new(cfg.report_path)
        when :yaml then RSpec::Undefined::Reporters::Yaml.new(cfg.report_path)
        when :markdown then RSpec::Undefined::Reporters::Markdown.new(cfg.report_path)
        end
      reporter.write if reporter
    end
  end
end

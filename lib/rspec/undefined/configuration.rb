# frozen_string_literal: true

module RSpec
  module Undefined
    class Configuration
      ALLOWED_FORMATS = [:json, :yaml, :markdown].freeze
      TRUE_VALUES = %w[1 true yes].freeze

      def initialize(env: ENV)
        @env = env
        @strict_explicit = nil
        @report_path = nil
        @report_format = :json
        @mutex = Mutex.new
      end

      def strict?
        @mutex.synchronize do
          return @strict_explicit unless @strict_explicit.nil?
          v = @env["RSPEC_UNDEFINED_STRICT"]
          return false if v.nil?
          TRUE_VALUES.include?(v.downcase)
        end
      end

      def strict=(value)
        @mutex.synchronize { @strict_explicit = value ? true : false }
      end

      def report_format=(value)
        unless ALLOWED_FORMATS.include?(value)
          raise ArgumentError, "report_format must be one of #{ALLOWED_FORMATS.inspect}"
        end
        @mutex.synchronize { @report_format = value }
      end

      def report_format
        @mutex.synchronize { @report_format }
      end

      def report_path
        @mutex.synchronize { @report_path }
      end

      def report_path=(value)
        @mutex.synchronize { @report_path = value }
      end

      def register_categories(*names)
        require "rspec/undefined/categories"
        Categories.register(*names)
      end
    end
  end
end

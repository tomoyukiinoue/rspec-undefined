# frozen_string_literal: true

module RSpec
  module Undefined
    class Configuration
      ALLOWED_FORMATS = [:json, :yaml].freeze
      TRUE_VALUES = %w[1 true yes].freeze

      attr_accessor :report_path
      attr_reader :report_format

      def initialize(env: ENV)
        @env = env
        @strict_explicit = nil
        @report_path = nil
        @report_format = :json
      end

      def strict?
        return @strict_explicit unless @strict_explicit.nil?
        v = @env["RSPEC_UNDEFINED_STRICT"]
        return false if v.nil?
        TRUE_VALUES.include?(v.to_s.downcase)
      end

      def strict=(value)
        @strict_explicit = value ? true : false
      end

      def report_format=(value)
        unless ALLOWED_FORMATS.include?(value)
          raise ArgumentError, "report_format must be one of #{ALLOWED_FORMATS.inspect}"
        end
        @report_format = value
      end
    end
  end
end

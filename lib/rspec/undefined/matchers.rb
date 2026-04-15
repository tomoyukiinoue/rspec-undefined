# frozen_string_literal: true

require "rspec/undefined/entry"

module RSpec
  module Undefined
    module Matchers
      class BaseMatcher
        attr_reader :matcher_name, :actual, :expected_recorded

        def initialize(matcher_name)
          @matcher_name = matcher_name
          @expected_recorded = :__any__
        end

        def matches?(actual)
          @actual = actual
          matched = evaluate(actual)
          record(matched)
          !RSpec::Undefined.configuration.strict?
        end

        def does_not_match?(actual)
          @actual = actual
          false
        end

        def failure_message
          "undefined[#{matcher_name}] at #{location_summary}: expected=#{@expected_recorded.inspect} actual=#{@actual.inspect}"
        end

        def failure_message_when_negated
          "undefined matcher (#{matcher_name}) は否定形では使えません"
        end

        def description
          "は未確定仕様 (#{matcher_name}) である"
        end

        private

        def evaluate(_actual)
          true
        end

        def record(matched)
          RSpec::Undefined.registry.add(
            RSpec::Undefined::Entry.new(
              kind: :matcher,
              matcher: matcher_name,
              expected: @expected_recorded,
              actual: @actual,
              matched: matched,
              location: location_summary,
              example_id: current_example_id
            )
          )
        end

        def location_summary
          frame = caller_locations(1, 20).find { |l| l.path !~ /lib\/rspec\/undefined/ }
          frame ? "#{frame.path}:#{frame.lineno}" : nil
        end

        def current_example_id
          ex = RSpec.current_example rescue nil
          ex && ex.id
        end
      end

      class BeUndefined < BaseMatcher
        def initialize
          super("be_undefined")
        end
      end

      class BeUndefinedNilOrEmpty < BaseMatcher
        def initialize
          super("be_undefined_nil_or_empty")
          @expected_recorded = :__nil_or_empty__
        end

        private

        def evaluate(actual)
          return true if actual.nil?
          return actual.empty? if actual.respond_to?(:empty?)
          false
        end
      end

      def be_undefined
        BeUndefined.new
      end

      def be_undefined_nil_or_empty
        BeUndefinedNilOrEmpty.new
      end

      class MatchUndefinedOrder < BaseMatcher
        def initialize(expected)
          super("match_undefined_order")
          @expected = expected
          @expected_recorded = expected
        end

        private

        def evaluate(actual)
          return false unless actual.is_a?(Array) && @expected.is_a?(Array)
          return false if actual.size != @expected.size
          begin
            @expected.sort == actual.sort
          rescue ArgumentError, TypeError
            nil
          end
        end
      end

      def match_undefined_order(expected)
        MatchUndefinedOrder.new(expected)
      end

      class UndefinedValueOf < BaseMatcher
        def initialize(inner)
          super("undefined_value_of")
          @inner = inner
          @expected_recorded = describe_inner(inner)
        end

        private

        def evaluate(actual)
          @inner.matches?(actual)
        end

        def describe_inner(inner)
          if inner.respond_to?(:description)
            inner.description
          else
            inner.class.name
          end
        end
      end

      def undefined_value_of(inner)
        UndefinedValueOf.new(inner)
      end
    end

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

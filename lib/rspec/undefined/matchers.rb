# frozen_string_literal: true

require "rspec/undefined/categories"
require "rspec/undefined/entry"

module RSpec
  module Undefined
    module Matchers
      class BeUndefined
        attr_reader :matcher_name, :actual, :expected_recorded, :category

        # kwarg: :expected_provided で「キーワードが明示された」を示す（nil 期待値との区別）
        def initialize(inner: nil, expected_value: nil, expected_provided: false, category: nil)
          @matcher_name = "be_undefined"
          @inner = inner
          @expected_value = expected_value
          @expected_provided = expected_provided
          @category = category
          @expected_recorded =
            if @inner
              describe_inner(@inner)
            elsif @expected_provided
              @expected_value.respond_to?(:description) ? @expected_value.description : @expected_value
            else
              :__any__
            end
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
          "undefined[#{matcher_name}] at #{location_summary}: " \
            "category=#{category.inspect} expected=#{@expected_recorded.inspect} actual=#{@actual.inspect}"
        end

        def failure_message_when_negated
          "undefined matcher は否定形では使えません"
        end

        def description
          suffix = category ? " [#{category}]" : ""
          "は未確定仕様#{suffix}である"
        end

        private

        def evaluate(actual)
          return !!@inner.matches?(actual) if @inner
          return compare_expected(actual) if @expected_provided
          true
        end

        def compare_expected(actual)
          if @expected_value.respond_to?(:matches?)
            !!@expected_value.matches?(actual)
          else
            actual == @expected_value
          end
        end

        def describe_inner(inner)
          if inner.respond_to?(:description)
            inner.description
          else
            inner.class.name
          end
        end

        def record(matched)
          RSpec::Undefined.registry.add(
            RSpec::Undefined::Entry.new(
              kind: :matcher,
              matcher: matcher_name,
              category: @category,
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

      NO_EXPECTED = Object.new.freeze
      private_constant :NO_EXPECTED if defined?(private_constant)

      def be_undefined(arg1 = nil, category = nil, expected: NO_EXPECTED)
        expected_provided = !expected.equal?(NO_EXPECTED)
        inner_arg = nil
        cat_arg = nil

        if arg1.nil?
          # noop
        elsif arg1.is_a?(Symbol)
          if !category.nil?
            raise ArgumentError,
                  "be_undefined: 第1引数がカテゴリ Symbol のとき、第2引数は指定できません"
          end
          cat_arg = arg1
        elsif arg1.respond_to?(:matches?)
          inner_arg = arg1
          cat_arg = category
        else
          raise ArgumentError,
                "be_undefined の第1引数は Symbol カテゴリまたは RSpec Matcher を渡してください（受け取った値: #{arg1.inspect}）。" \
                "素値を期待値として渡したい場合は expected: キーワードを使ってください (例: be_undefined(:category, expected: #{arg1.inspect}))"
        end

        if inner_arg && expected_provided
          raise ArgumentError,
                "be_undefined: 内側マッチャと expected: は同時に指定できません（排他）"
        end

        unless cat_arg.nil? || cat_arg.is_a?(Symbol)
          raise ArgumentError,
                "category は Symbol で指定してください（受け取った値: #{cat_arg.inspect}）。" \
                "カスタムカテゴリは RSpec::Undefined::Categories.register で事前登録してください。"
        end

        BeUndefined.new(
          inner: inner_arg,
          expected_value: expected_provided ? expected : nil,
          expected_provided: expected_provided,
          category: cat_arg
        )
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

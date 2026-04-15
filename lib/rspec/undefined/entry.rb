# frozen_string_literal: true

module RSpec
  module Undefined
    class Entry
      ATTRS = [:kind, :matcher, :description, :expected, :actual,
               :matched, :location, :example_id].freeze

      attr_reader(*ATTRS)

      def initialize(attrs = {})
        ATTRS.each { |a| instance_variable_set("@#{a}", attrs[a]) }
      end

      def to_h
        ATTRS.each_with_object({}) { |a, h| h[a] = instance_variable_get("@#{a}") }
      end
    end
  end
end

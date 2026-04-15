# frozen_string_literal: true

module RSpec
  module Undefined
    module Categories
      STANDARD = [
        :boundary,
        :nil_or_empty,
        :uniqueness,
        :order,
        :datetime,
        :encoding,
        :rounding,
        :permission,
        :state_transition,
        :concurrency,
        :deletion,
        :retroactive,
        :idempotency
      ].freeze

      @registered = []
      @mutex = Mutex.new

      def self.register(*names)
        @mutex.synchronize do
          names.each do |n|
            @registered << n unless @registered.include?(n) || STANDARD.include?(n)
          end
        end
        self
      end

      def self.registered
        @mutex.synchronize { @registered.dup }
      end

      def self.all
        STANDARD + registered
      end

      def self.known?(value)
        return false if value.nil?
        all.include?(value)
      end

      def self.reset_registered!
        @mutex.synchronize { @registered.clear }
      end
    end
  end
end

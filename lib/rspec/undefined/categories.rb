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
    end
  end
end

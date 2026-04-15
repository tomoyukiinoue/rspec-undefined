# frozen_string_literal: true

require "rspec/core"
require "rspec/undefined/entry"

module RSpec
  module Undefined
    module DSL
      def undefined(description, category: nil, &block)
        loc = caller_locations(1, 1).first
        location = loc ? "#{loc.path}:#{loc.lineno}" : nil
        example("[undefined] #{description}", undefined: true, undefined_category: category) do
          RSpec::Undefined.registry.add(
            RSpec::Undefined::Entry.new(
              kind: :declaration,
              description: description,
              category: category,
              location: location,
              example_id: RSpec.current_example && RSpec.current_example.id
            )
          )

          if RSpec::Undefined.configuration.strict?
            raise RSpec::Expectations::ExpectationNotMetError,
                  "undefined declaration (strict mode): #{description}"
          end

          if block
            begin
              instance_exec(&block)
            rescue RSpec::Expectations::ExpectationNotMetError
              # 通常モードではブロック内 failure を握り潰す
            end
          end
        end
      end
    end
  end
end

RSpec::Core::ExampleGroup.singleton_class.send(:include, RSpec::Undefined::DSL)

# frozen_string_literal: true

require "rspec/core"
require "rspec/undefined/entry"
require "rspec/undefined/registry"
require "rspec/undefined/configuration"

module RSpec
  module Undefined
    module DSL
      def undefined(description, &block)
        loc = caller_locations(1, 1).first
        location = loc ? "#{loc.path}:#{loc.lineno}" : nil
        example("[undefined] #{description}", undefined: true) do
          RSpec::Undefined::Registry.instance.add(
            RSpec::Undefined::Entry.new(
              kind: :declaration,
              description: description,
              location: location,
              example_id: RSpec.current_example && RSpec.current_example.id
            )
          )

          if RSpec::Undefined::Configuration.new.strict?
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

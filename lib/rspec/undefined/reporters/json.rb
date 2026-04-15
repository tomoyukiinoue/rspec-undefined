# frozen_string_literal: true

require "json"

module RSpec
  module Undefined
    module Reporters
      class Json
        SENTINELS = {
          __any__: "__any__",
          __nil_or_empty__: "__nil_or_empty__"
        }.freeze

        def initialize(path, stderr: $stderr)
          @path = path
          @stderr = stderr
        end

        def write
          entries = RSpec::Undefined.registry.all
          payload = {
            "count" => entries.size,
            "entries" => entries.map { |e| serialize(e) }
          }
          File.write(@path, JSON.pretty_generate(payload))
        rescue SystemCallError, IOError => ex
          @stderr.puts "[rspec-undefined] failed to write #{@path}: #{ex.message}"
        end

        private

        def serialize(entry)
          h = entry.to_h
          result = {}
          h.each do |k, v|
            result[k.to_s] = normalize(v)
          end
          result
        end

        def normalize(value)
          if value.is_a?(Symbol) && SENTINELS.key?(value)
            SENTINELS[value]
          elsif value.is_a?(Symbol)
            value.to_s
          else
            value
          end
        end
      end
    end
  end
end

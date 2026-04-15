# frozen_string_literal: true

require "yaml"

module RSpec
  module Undefined
    module Reporters
      class Yaml
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
          File.write(@path, YAML.dump(payload))
        rescue SystemCallError, IOError => ex
          @stderr.puts "[rspec-undefined] failed to write #{@path}: #{ex.message}"
        end

        private

        def serialize(entry)
          entry.to_h.each_with_object({}) do |(k, v), h|
            h[k.to_s] = normalize(v)
          end
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

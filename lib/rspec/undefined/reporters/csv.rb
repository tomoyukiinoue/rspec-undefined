# frozen_string_literal: true

require "csv"

module RSpec
  module Undefined
    module Reporters
      class Csv
        SENTINELS = {
          __any__: "__any__",
          __nil_or_empty__: "__nil_or_empty__"
        }.freeze

        HEADERS = %w[kind matcher category description expected actual matched location].freeze

        def initialize(path, stderr: $stderr)
          @path = path
          @stderr = stderr
        end

        def write
          entries = RSpec::Undefined.registry.all
          ::CSV.open(@path, "w") do |csv|
            csv << HEADERS
            entries.each { |e| csv << row_for(e) }
          end
        rescue SystemCallError, IOError => ex
          @stderr.puts "[rspec-undefined] failed to write #{@path}: #{ex.message}"
        end

        private

        def row_for(entry)
          [
            entry.kind,
            entry.matcher,
            entry.category,
            entry.description,
            format_value(entry.expected),
            format_value(entry.actual),
            entry.matched,
            entry.location
          ].map { |v| stringify(v) }
        end

        def format_value(v)
          if v.is_a?(Symbol) && SENTINELS.key?(v)
            SENTINELS[v]
          elsif v.is_a?(Symbol)
            v.to_s
          else
            v.inspect
          end
        end

        def stringify(v)
          return "" if v.nil?
          v.is_a?(String) ? v : v.to_s
        end
      end
    end
  end
end

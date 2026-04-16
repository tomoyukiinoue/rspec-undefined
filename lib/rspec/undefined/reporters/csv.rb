# frozen_string_literal: true

require "csv"
require "rspec/undefined/sentinels"

module RSpec
  module Undefined
    module Reporters
      class Csv
        HEADERS = %w[kind matcher category description expected actual matched location].freeze

        def initialize(path, stderr: $stderr)
          @path = path
          @stderr = stderr
        end

        def write
          entries = RSpec::Undefined.registry.all
          tmp_path = "#{@path}.tmp.#{Process.pid}"
          begin
            write_body(tmp_path, entries)
            File.rename(tmp_path, @path)
          rescue SystemCallError, IOError => ex
            File.delete(tmp_path) if File.exist?(tmp_path)
            @stderr.puts "[rspec-undefined] failed to write #{@path}: #{ex.message}"
          end
        end

        private

        def write_body(path, entries)
          ::CSV.open(path, "w") do |csv|
            csv << HEADERS
            entries.each { |e| csv << row_for(e) }
          end
        end

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
          Sentinels.normalize(v, &:inspect)
        end

        def stringify(v)
          return "" if v.nil?
          v.is_a?(String) ? v : v.to_s
        end
      end
    end
  end
end

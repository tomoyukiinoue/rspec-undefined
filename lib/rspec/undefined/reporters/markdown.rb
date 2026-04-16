# frozen_string_literal: true

require "rspec/undefined/sentinels"

module RSpec
  module Undefined
    module Reporters
      class Markdown
        HEADERS = %w[No. kind matcher category description expected actual matched location].freeze

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
          File.write(path, render(entries))
        end

        def render(entries)
          lines = []
          lines << "# Undefined spec items"
          lines << ""
          lines << "Total: #{entries.size}"
          lines << ""
          lines << "| #{HEADERS.join(' | ')} |"
          lines << "| #{HEADERS.map { '---' }.join(' | ')} |"
          entries.each_with_index do |e, i|
            lines << "| #{row_for(i + 1, e).map { |c| escape(c) }.join(' | ')} |"
          end
          lines.join("\n") + "\n"
        end

        def row_for(index, entry)
          [
            index,
            entry.kind,
            entry.matcher,
            entry.category,
            entry.description,
            format_value(entry.expected),
            format_value(entry.actual),
            entry.matched,
            entry.location
          ]
        end

        def format_value(v)
          Sentinels.normalize(v) { |x| x.inspect }
        end

        def escape(v)
          s = v.nil? ? "" : v.to_s
          s.gsub("|", "\\|").gsub(/\r?\n/, " ")
        end
      end
    end
  end
end

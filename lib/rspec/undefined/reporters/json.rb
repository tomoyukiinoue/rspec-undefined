# frozen_string_literal: true

require "json"
require "rspec/undefined/sentinels"

module RSpec
  module Undefined
    module Reporters
      class Json
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
          payload = {
            "count" => entries.size,
            "entries" => entries.map { |e| serialize(e) }
          }
          File.write(path, JSON.pretty_generate(payload))
        end

        def serialize(entry)
          h = entry.to_h
          result = {}
          h.each do |k, v|
            result[k.to_s] = normalize(v)
          end
          result
        end

        def normalize(value)
          Sentinels.normalize(value)
        end
      end
    end
  end
end

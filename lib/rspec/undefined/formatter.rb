# frozen_string_literal: true

module RSpec
  module Undefined
    class Formatter
      UNCATEGORIZED = "(uncategorized)"

      def initialize(output = $stdout)
        @output = output
      end

      def dump_summary(_notification)
        entries = RSpec::Undefined.registry.all
        return if entries.empty?

        @output.puts
        @output.puts "Undefined spec items:"
        entries.each_with_index do |e, i|
          @output.puts format_entry(i + 1, e)
        end
        @output.puts
        @output.puts "undefined: #{entries.size}"
        dump_by_category(entries)
      end

      private

      def format_entry(index, entry)
        head = "  #{index}) [#{entry.kind}]"
        cat  = entry.category ? " {#{entry.category}}" : ""
        body =
          if entry.kind == :matcher
            "#{entry.matcher} expected=#{entry.expected.inspect} actual=#{entry.actual.inspect} matched=#{entry.matched.inspect}"
          else
            entry.description.to_s
          end
        "#{head}#{cat} #{body} (#{entry.location})"
      end

      def dump_by_category(entries)
        require "rspec/undefined/categories"

        counts = Hash.new(0)
        entries.each do |e|
          key = e.category.nil? ? UNCATEGORIZED : e.category.to_s
          counts[key] += 1
        end
        @output.puts "by category:"
        counts.sort_by { |k, _| k }.each do |k, v|
          mark = marker_for(k, entries)
          @output.puts "  #{k}#{mark}: #{v}"
        end
      end

      def marker_for(key, entries)
        return "" if key == UNCATEGORIZED
        original = entries.map(&:category).compact.find { |c| c.to_s == key }
        RSpec::Undefined::Categories.known?(original) ? "" : "*"
      end
    end
  end
end

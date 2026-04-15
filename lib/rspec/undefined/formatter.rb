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

        groups = entries.group_by { |e| e.category.nil? ? UNCATEGORIZED : e.category.to_s }
        sample_category = entries.each_with_object({}) do |e, h|
          next if e.category.nil?
          h[e.category.to_s] ||= e.category
        end

        @output.puts "by category:"
        groups.sort_by { |k, _| k }.each do |k, items|
          mark = if k == UNCATEGORIZED
                   ""
                 elsif RSpec::Undefined::Categories.known?(sample_category[k])
                   ""
                 else
                   "*"
                 end
          @output.puts "  #{k}#{mark}: #{items.size}"
        end
      end
    end
  end
end

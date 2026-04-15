# frozen_string_literal: true

require "thread"

module RSpec
  module Undefined
    class Registry
      def initialize
        @mutex = Mutex.new
        @entries = []
      end

      def add(entry)
        @mutex.synchronize { @entries << entry }
        entry
      end

      def all
        @mutex.synchronize { @entries.dup }
      end

      def clear
        @mutex.synchronize { @entries.clear }
      end

      @singleton_mutex = Mutex.new

      def self.instance
        @singleton_mutex.synchronize { @instance ||= new }
      end

      def self.reset!
        @singleton_mutex.synchronize { @instance = nil }
      end
    end
  end
end

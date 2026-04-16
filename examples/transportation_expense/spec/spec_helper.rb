require "rspec/undefined"
require_relative "../lib/transportation_expense"

RSpec::Undefined.configure do |c|
  c.register_categories :tax_handling
end

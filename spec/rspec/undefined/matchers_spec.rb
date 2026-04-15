# frozen_string_literal: true

require "rspec/undefined/configuration"
require "rspec/undefined/entry"
require "rspec/undefined/registry"
require "rspec/undefined/matchers"

RSpec.describe "RSpec::Undefined::Matchers#be_undefined" do
  include RSpec::Undefined::Matchers

  let(:registry) { RSpec::Undefined::Registry.new }
  let(:config)   { RSpec::Undefined::Configuration.new(env: {}) }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    allow(RSpec::Undefined).to receive(:configuration).and_return(config)
  end

  it "常にマッチし Registry に記録する" do
    matcher = be_undefined
    expect(matcher.matches?(42)).to eq(true)
    expect(registry.all.size).to eq(1)
    entry = registry.all.first
    expect(entry.kind).to eq(:matcher)
    expect(entry.matcher).to eq("be_undefined")
    expect(entry.actual).to eq(42)
    expect(entry.expected).to eq(:__any__)
    expect(entry.matched).to eq(true)
  end

  it "strict モードでは matches? が false" do
    config.strict = true
    matcher = be_undefined
    expect(matcher.matches?(42)).to eq(false)
    expect(matcher.failure_message).to include("undefined")
  end
end

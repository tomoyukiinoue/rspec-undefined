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

RSpec.describe "RSpec::Undefined::Matchers#be_undefined_nil_or_empty" do
  include RSpec::Undefined::Matchers

  let(:registry) { RSpec::Undefined::Registry.new }
  let(:config)   { RSpec::Undefined::Configuration.new(env: {}) }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    allow(RSpec::Undefined).to receive(:configuration).and_return(config)
  end

  it "nil は matched=true" do
    be_undefined_nil_or_empty.matches?(nil)
    expect(registry.all.first.matched).to eq(true)
  end

  it "空配列は matched=true" do
    be_undefined_nil_or_empty.matches?([])
    expect(registry.all.first.matched).to eq(true)
  end

  it "要素ありの配列は matched=false" do
    be_undefined_nil_or_empty.matches?([1])
    expect(registry.all.first.matched).to eq(false)
  end

  it "empty? を持たない値は matched=false" do
    be_undefined_nil_or_empty.matches?(42)
    expect(registry.all.first.matched).to eq(false)
  end

  it "通常モードでは matches? は true を返す" do
    expect(be_undefined_nil_or_empty.matches?([1])).to eq(true)
  end

  it "strict モードでは matches? が false" do
    config.strict = true
    expect(be_undefined_nil_or_empty.matches?([1])).to eq(false)
  end
end

RSpec.describe "RSpec::Undefined::Matchers#match_undefined_order" do
  include RSpec::Undefined::Matchers

  let(:registry) { RSpec::Undefined::Registry.new }
  let(:config)   { RSpec::Undefined::Configuration.new(env: {}) }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    allow(RSpec::Undefined).to receive(:configuration).and_return(config)
  end

  it "同じ要素・異なる順序なら matched=true" do
    match_undefined_order([1, 2, 3]).matches?([3, 1, 2])
    entry = registry.all.first
    expect(entry.matched).to eq(true)
    expect(entry.expected).to eq([1, 2, 3])
    expect(entry.actual).to eq([3, 1, 2])
  end

  it "要素が違えば matched=false" do
    match_undefined_order([1, 2, 3]).matches?([1, 2])
    expect(registry.all.first.matched).to eq(false)
  end

  it "比較不能値は matched=nil" do
    match_undefined_order([1, "a"]).matches?(["a", 1])
    expect(registry.all.first.matched).to be_nil
  end

  it "通常モードでは matches? は常に true" do
    expect(match_undefined_order([1]).matches?([2, 3])).to eq(true)
  end
end

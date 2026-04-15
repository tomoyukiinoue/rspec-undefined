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

RSpec.describe "RSpec::Undefined::Matchers#undefined_value_of" do
  include RSpec::Undefined::Matchers

  let(:registry) { RSpec::Undefined::Registry.new }
  let(:config)   { RSpec::Undefined::Configuration.new(env: {}) }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    allow(RSpec::Undefined).to receive(:configuration).and_return(config)
  end

  it "内側マッチャが通れば matched=true" do
    undefined_value_of(eq(3)).matches?(3)
    expect(registry.all.first.matched).to eq(true)
  end

  it "内側マッチャが落ちれば matched=false" do
    undefined_value_of(eq(3)).matches?(4)
    expect(registry.all.first.matched).to eq(false)
  end

  it "期待値に内側 description を記録する" do
    undefined_value_of(eq(3)).matches?(3)
    expect(registry.all.first.expected).to include("3")
  end

  it "通常モードでは常に matches? は true" do
    expect(undefined_value_of(eq(3)).matches?(4)).to eq(true)
  end
end

RSpec.describe "RSpec::Undefined::Matchers (category)" do
  include RSpec::Undefined::Matchers

  let(:registry) { RSpec::Undefined::Registry.new }
  let(:config)   { RSpec::Undefined::Configuration.new(env: {}) }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    allow(RSpec::Undefined).to receive(:configuration).and_return(config)
  end

  it "be_undefined にカテゴリを渡すと Entry に記録される" do
    be_undefined(:boundary).matches?(100)
    expect(registry.all.first.category).to eq(:boundary)
  end

  it "be_undefined_nil_or_empty の既定カテゴリは :nil_or_empty" do
    be_undefined_nil_or_empty.matches?(nil)
    expect(registry.all.first.category).to eq(:nil_or_empty)
  end

  it "be_undefined_nil_or_empty は任意のカテゴリで上書きできる" do
    be_undefined_nil_or_empty(:deletion).matches?(nil)
    expect(registry.all.first.category).to eq(:deletion)
  end

  it "match_undefined_order の既定カテゴリは :order" do
    match_undefined_order([1, 2]).matches?([2, 1])
    expect(registry.all.first.category).to eq(:order)
  end

  it "match_undefined_order はカテゴリを上書きできる" do
    match_undefined_order([1, 2], category: :deletion).matches?([1, 2])
    expect(registry.all.first.category).to eq(:deletion)
  end

  it "undefined_value_of にカテゴリを渡せる" do
    undefined_value_of(eq(3), category: :rounding).matches?(3)
    expect(registry.all.first.category).to eq(:rounding)
  end

  it "カテゴリ未指定時は nil" do
    be_undefined.matches?(1)
    expect(registry.all.first.category).to be_nil
  end
end

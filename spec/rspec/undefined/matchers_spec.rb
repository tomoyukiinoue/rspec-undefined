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

  describe "引数なし" do
    it "常に true を返し、actual のみ記録" do
      expect(be_undefined.matches?(42)).to eq(true)
      entry = registry.all.first
      expect(entry.category).to be_nil
      expect(entry.expected).to eq(:__any__)
      expect(entry.actual).to eq(42)
      expect(entry.matched).to eq(true)
    end

    it "strict モードでは false" do
      config.strict = true
      expect(be_undefined.matches?(42)).to eq(false)
    end
  end

  describe "Symbol カテゴリのみ" do
    it "カテゴリを Entry に記録する" do
      be_undefined(:boundary).matches?(100)
      expect(registry.all.first.category).to eq(:boundary)
    end

    it "第2引数を一緒に渡すと ArgumentError" do
      expect { be_undefined(:boundary, :other) }.to raise_error(ArgumentError)
    end
  end

  describe "内側マッチャ" do
    it "内側マッチャが true なら matched=true" do
      be_undefined(eq(3)).matches?(3)
      expect(registry.all.first.matched).to eq(true)
    end

    it "内側マッチャが false なら matched=false" do
      be_undefined(eq(3)).matches?(4)
      expect(registry.all.first.matched).to eq(false)
    end

    it "expected には内側 description が記録される" do
      be_undefined(eq(3)).matches?(3)
      expect(registry.all.first.expected).to include("3")
    end

    it "第2引数でカテゴリも指定できる" do
      be_undefined(eq(3), :rounding).matches?(3)
      expect(registry.all.first.category).to eq(:rounding)
    end

    it "内側マッチャと match_array の併用" do
      be_undefined(match_array([1, 2, 3]), :order).matches?([3, 1, 2])
      entry = registry.all.first
      expect(entry.matched).to eq(true)
      expect(entry.category).to eq(:order)
    end

    it "通常モードでは matches? は常に true" do
      expect(be_undefined(eq(3)).matches?(4)).to eq(true)
    end
  end

  describe "異常系" do
    it "String は ArgumentError" do
      expect { be_undefined("str") }.to raise_error(ArgumentError, /Symbol|Matcher/)
    end

    it "内側マッチャ + String カテゴリは ArgumentError" do
      expect { be_undefined(eq(3), "str") }.to raise_error(ArgumentError, /Symbol/)
    end
  end
end

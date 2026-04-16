# frozen_string_literal: true

require "rspec/undefined/sentinels"

RSpec.describe RSpec::Undefined::Sentinels do
  describe ".normalize" do
    it "Sentinel Symbol は to_s で文字列化する" do
      expect(described_class.normalize(:__any__)).to eq("__any__")
    end

    it "通常の Symbol も to_s で文字列化する" do
      expect(described_class.normalize(:boundary)).to eq("boundary")
    end

    it "非 Symbol はブロック無しならそのまま返す" do
      expect(described_class.normalize(42)).to eq(42)
      expect(described_class.normalize("str")).to eq("str")
      expect(described_class.normalize(nil)).to be_nil
    end

    it "非 Symbol はブロックが与えられればその結果を返す" do
      expect(described_class.normalize(42, &:inspect)).to eq("42")
      expect(described_class.normalize("str", &:inspect)).to eq('"str"')
    end

    it "Symbol に対してはブロックが呼ばれない" do
      expect { |b| described_class.normalize(:__any__, &b) }.not_to yield_control
    end
  end
end

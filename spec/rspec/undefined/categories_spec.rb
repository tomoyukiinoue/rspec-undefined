# frozen_string_literal: true

require "rspec/undefined/categories"

RSpec.describe RSpec::Undefined::Categories do
  after { described_class.reset_registered! }

  describe ".STANDARD" do
    it "13 種類の標準カテゴリを持つ" do
      expect(described_class::STANDARD.size).to eq(13)
      expect(described_class::STANDARD).to include(:boundary, :idempotency)
    end

    it "freeze されている" do
      expect(described_class::STANDARD).to be_frozen
    end
  end

  describe ".register" do
    it "Symbol を登録できる" do
      described_class.register(:custom_a, :custom_b)
      expect(described_class.registered).to include(:custom_a, :custom_b)
    end

    it "String も登録できる" do
      described_class.register("特殊ケース")
      expect(described_class.registered).to include("特殊ケース")
    end

    it "重複登録は無視される" do
      described_class.register(:x)
      described_class.register(:x)
      expect(described_class.registered.count(:x)).to eq(1)
    end

    it "STANDARD に含まれる値は登録されない" do
      described_class.register(:boundary)
      expect(described_class.registered).not_to include(:boundary)
    end
  end

  describe ".all" do
    it "STANDARD + registered" do
      described_class.register(:extra)
      expect(described_class.all).to include(:boundary, :extra)
    end
  end

  describe ".known?" do
    it "STANDARD に含まれる値は true" do
      expect(described_class.known?(:boundary)).to eq(true)
    end

    it "登録済みは true" do
      described_class.register(:extra)
      expect(described_class.known?(:extra)).to eq(true)
    end

    it "未登録は false" do
      expect(described_class.known?(:unknown)).to eq(false)
    end

    it "nil は false" do
      expect(described_class.known?(nil)).to eq(false)
    end
  end
end

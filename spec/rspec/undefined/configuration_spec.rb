# frozen_string_literal: true

require "rspec/undefined/configuration"
require "rspec/undefined/categories"

RSpec.describe RSpec::Undefined::Configuration do
  subject(:config) { described_class.new(env: env) }
  let(:env) { {} }

  describe "#strict?" do
    it "既定では false" do
      expect(config.strict?).to eq(false)
    end

    it "RSPEC_UNDEFINED_STRICT=1 で true" do
      config = described_class.new(env: { "RSPEC_UNDEFINED_STRICT" => "1" })
      expect(config.strict?).to eq(true)
    end

    %w[true TRUE yes YES 1].each do |v|
      it "環境変数 '#{v}' で true" do
        config = described_class.new(env: { "RSPEC_UNDEFINED_STRICT" => v })
        expect(config.strict?).to eq(true)
      end
    end

    it "明示代入が環境変数より優先される" do
      config = described_class.new(env: { "RSPEC_UNDEFINED_STRICT" => "1" })
      config.strict = false
      expect(config.strict?).to eq(false)
    end
  end

  describe "#register_categories" do
    after { RSpec::Undefined::Categories.reset_registered! }

    it "Categories.register を呼び出す" do
      config.register_categories(:custom_a, :custom_b)
      expect(RSpec::Undefined::Categories.registered).to include(:custom_a, :custom_b)
    end
  end

  describe "#report_path / #report_format" do
    it "report_path の既定は nil" do
      expect(config.report_path).to be_nil
    end

    it "report_format の既定は :json" do
      expect(config.report_format).to eq(:json)
    end

    [:json, :yaml, :csv, :markdown].each do |fmt|
      it ":#{fmt} を代入できる" do
        config.report_format = fmt
        expect(config.report_format).to eq(fmt)
      end
    end

    it "未知のフォーマットは ArgumentError" do
      expect { config.report_format = :xml }.to raise_error(ArgumentError, /report_format/)
    end
  end
end

# frozen_string_literal: true

require "stringio"
require "rspec/undefined/entry"
require "rspec/undefined/registry"
require "rspec/undefined/formatter"
require "rspec/undefined/categories"

RSpec.describe RSpec::Undefined::Formatter do
  let(:io) { StringIO.new }
  let(:registry) { RSpec::Undefined::Registry.new }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
  end

  context "複数エントリあり" do
    before do
      registry.add(RSpec::Undefined::Entry.new(
        kind: :matcher, matcher: "be_undefined", category: :boundary,
        expected: :__any__, actual: 42, matched: true,
        location: "spec/x_spec.rb:10", description: nil
      ))
      registry.add(RSpec::Undefined::Entry.new(
        kind: :declaration, description: "順序未確定", category: :order,
        location: "spec/y_spec.rb:5"
      ))
      registry.add(RSpec::Undefined::Entry.new(
        kind: :matcher, matcher: "be_undefined", category: :boundary,
        expected: :__any__, actual: 99, matched: true,
        location: "spec/z_spec.rb:3"
      ))
    end

    it "合計件数を出力する" do
      described_class.new(io).dump_summary(nil)
      expect(io.string).to include("undefined: 3")
    end

    it "詳細リストを出力する" do
      described_class.new(io).dump_summary(nil)
      expect(io.string).to include("spec/x_spec.rb:10")
      expect(io.string).to include("spec/y_spec.rb:5")
      expect(io.string).to include("be_undefined")
      expect(io.string).to include("順序未確定")
    end

    it "カテゴリ別件数を出力する" do
      described_class.new(io).dump_summary(nil)
      expect(io.string).to match(/boundary:\s*2/)
      expect(io.string).to match(/order:\s*1/)
    end

    it "location を出力する" do
      described_class.new(io).dump_summary(nil)
      expect(io.string).to include("spec/z_spec.rb:3")
    end
  end

  context "カテゴリなしエントリを含む" do
    before do
      registry.add(RSpec::Undefined::Entry.new(
        kind: :matcher, matcher: "be_undefined", category: nil,
        expected: :__any__, actual: 1, matched: true,
        location: "spec/a.rb:1"
      ))
    end

    it "カテゴリなしは (uncategorized) と表記する" do
      described_class.new(io).dump_summary(nil)
      expect(io.string).to match(/\(uncategorized\):\s*1/)
    end
  end

  context "0 件" do
    it "何も出力しない" do
      described_class.new(io).dump_summary(nil)
      expect(io.string).to eq("")
    end
  end

  context "未登録カテゴリ" do
    after { RSpec::Undefined::Categories.reset_registered! }

    before do
      registry.add(RSpec::Undefined::Entry.new(
        kind: :matcher, matcher: "be_undefined", category: :unknown_cat,
        expected: :__any__, actual: 1, matched: true, location: "spec/a.rb:1"
      ))
    end

    it "未登録カテゴリに * マーカーが付く" do
      described_class.new(io).dump_summary(nil)
      expect(io.string).to match(/unknown_cat\*:\s*1/)
    end

    it "register 済みカテゴリにはマーカーが付かない" do
      RSpec::Undefined::Categories.register(:unknown_cat)
      described_class.new(io).dump_summary(nil)
      expect(io.string).to match(/unknown_cat:\s*1/)
      expect(io.string).not_to match(/unknown_cat\*/)
    end
  end

  context "STANDARD カテゴリ" do
    before do
      registry.add(RSpec::Undefined::Entry.new(
        kind: :matcher, matcher: "be_undefined", category: :boundary,
        expected: :__any__, actual: 1, matched: true, location: "spec/a.rb:1"
      ))
    end

    it "STANDARD カテゴリにはマーカーが付かない" do
      described_class.new(io).dump_summary(nil)
      expect(io.string).not_to match(/boundary\*/)
    end
  end
end

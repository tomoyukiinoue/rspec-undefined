# frozen_string_literal: true

require "csv"
require "stringio"
require "tempfile"
require "rspec/undefined/entry"
require "rspec/undefined/registry"
require "rspec/undefined/reporters/csv"

RSpec.describe RSpec::Undefined::Reporters::Csv do
  let(:registry) { RSpec::Undefined::Registry.new }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    registry.add(RSpec::Undefined::Entry.new(
      kind: :matcher, matcher: "be_undefined", category: :boundary,
      expected: :__any__, actual: 42, matched: true,
      location: "spec/x_spec.rb:10"
    ))
    registry.add(RSpec::Undefined::Entry.new(
      kind: :declaration, description: "未確定",
      category: :order, location: "spec/y_spec.rb:5"
    ))
  end

  it "CSV を書き出す" do
    Tempfile.create(["rep", ".csv"]) do |f|
      described_class.new(f.path).write
      rows = CSV.read(f.path)
      expect(rows[0]).to eq(%w[kind matcher category description expected actual matched location])
      expect(rows.size).to eq(3)
      expect(rows[1][0]).to eq("matcher")
      expect(rows[1][2]).to eq("boundary")
      expect(rows[2][0]).to eq("declaration")
      expect(rows[2][3]).to eq("未確定")
    end
  end

  it "センチネル値を文字列化する" do
    Tempfile.create(["rep", ".csv"]) do |f|
      described_class.new(f.path).write
      rows = CSV.read(f.path)
      expect(rows[1][4]).to eq("__any__")
    end
  end

  it "書き込み失敗時は stderr 警告のみ" do
    err = StringIO.new
    r = described_class.new("/nonexistent/dir/out.csv", stderr: err)
    expect { r.write }.not_to raise_error
    expect(err.string).to include("rspec-undefined")
  end
end

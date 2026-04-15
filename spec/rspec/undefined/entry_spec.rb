# frozen_string_literal: true

require "rspec/undefined/entry"

RSpec.describe RSpec::Undefined::Entry do
  it "属性を持つ" do
    entry = described_class.new(
      kind: :matcher,
      matcher: "be_undefined",
      description: "desc",
      expected: :__any__,
      actual: 42,
      matched: true,
      location: "spec/x_spec.rb:10",
      example_id: "./spec/x_spec.rb[1:1]"
    )
    expect(entry.kind).to eq(:matcher)
    expect(entry.matcher).to eq("be_undefined")
    expect(entry.description).to eq("desc")
    expect(entry.expected).to eq(:__any__)
    expect(entry.actual).to eq(42)
    expect(entry.matched).to eq(true)
    expect(entry.location).to eq("spec/x_spec.rb:10")
    expect(entry.example_id).to eq("./spec/x_spec.rb[1:1]")
  end

  it "ハッシュに変換できる" do
    entry = described_class.new(kind: :declaration, description: "d", location: "spec/y.rb:1")
    h = entry.to_h
    expect(h[:kind]).to eq(:declaration)
    expect(h[:description]).to eq("d")
    expect(h[:location]).to eq("spec/y.rb:1")
    expect(h[:matcher]).to be_nil
  end

  it "category 属性を受け取る" do
    entry = described_class.new(kind: :matcher, category: :boundary)
    expect(entry.category).to eq(:boundary)
    expect(entry.to_h[:category]).to eq(:boundary)
  end

  it "category 未指定時は nil" do
    entry = described_class.new(kind: :declaration)
    expect(entry.category).to be_nil
  end
end

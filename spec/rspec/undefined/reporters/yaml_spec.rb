# frozen_string_literal: true

require "yaml"
require "stringio"
require "tempfile"
require "rspec/undefined/entry"
require "rspec/undefined/registry"
require "rspec/undefined/reporters/yaml"

RSpec.describe RSpec::Undefined::Reporters::Yaml do
  # YAML.safe_load with keyword arguments (permitted_classes:) requires Psych 3.1+.
  # Ruby 2.0 ships Psych 2.0 which lacks safe_load entirely.
  # On Ruby 2.2+, bundler typically pulls in a newer psych gem that supports kwargs.
  before(:all) do
    skip "YAML.safe_load not available in this Psych version" unless YAML.respond_to?(:safe_load)
  end

  let(:registry) { RSpec::Undefined::Registry.new }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    registry.add(RSpec::Undefined::Entry.new(
      kind: :declaration, description: "順序未確定", category: :order,
      location: "spec/x_spec.rb:10"
    ))
    registry.add(RSpec::Undefined::Entry.new(
      kind: :matcher, matcher: "be_undefined", category: :boundary,
      expected: :__any__, actual: 42, matched: true,
      location: "spec/y_spec.rb:5"
    ))
  end

  it "YAML を書き出す" do
    Tempfile.create(["rep", ".yml"]) do |f|
      described_class.new(f.path).write
      data = YAML.safe_load(File.read(f.path), permitted_classes: [Symbol], aliases: true)
      expect(data["count"]).to eq(2)
      expect(data["entries"][0]["description"]).to eq("順序未確定")
      expect(data["entries"][0]["category"]).to eq("order")
      expect(data["entries"][1]["matcher"]).to eq("be_undefined")
    end
  end

  it "センチネル値を文字列化する" do
    Tempfile.create(["rep", ".yml"]) do |f|
      described_class.new(f.path).write
      data = YAML.safe_load(File.read(f.path), permitted_classes: [Symbol], aliases: true)
      expect(data["entries"][1]["expected"]).to eq("__any__")
    end
  end

  it "category が nil のエントリも書ける" do
    registry.clear
    registry.add(RSpec::Undefined::Entry.new(
      kind: :declaration, description: "x", category: nil, location: "spec/a.rb:1"
    ))
    Tempfile.create(["rep", ".yml"]) do |f|
      described_class.new(f.path).write
      data = YAML.safe_load(File.read(f.path), permitted_classes: [Symbol], aliases: true)
      expect(data["entries"][0]["category"]).to be_nil
    end
  end

  it "書き込み失敗時は stderr に警告し例外を上げない" do
    err = StringIO.new
    r = described_class.new("/nonexistent/dir/out.yml", stderr: err)
    expect { r.write }.not_to raise_error
    expect(err.string).to include("rspec-undefined")
  end

  it "失敗時に tmp ファイルを残さない" do
    err = StringIO.new
    bad_path = "/nonexistent/dir/out.yml"
    described_class.new(bad_path, stderr: err).write
    expect(Dir.glob("#{File.dirname(bad_path)}/*.tmp*")).to be_empty
  end
end

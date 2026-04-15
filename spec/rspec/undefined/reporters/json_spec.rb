# frozen_string_literal: true

require "json"
require "stringio"
require "tempfile"
require "rspec/undefined/entry"
require "rspec/undefined/registry"
require "rspec/undefined/reporters/json"

RSpec.describe RSpec::Undefined::Reporters::Json do
  let(:registry) { RSpec::Undefined::Registry.new }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    registry.add(RSpec::Undefined::Entry.new(
      kind: :matcher, matcher: "be_undefined", category: :boundary,
      expected: :__any__, actual: 42, matched: true,
      location: "spec/x_spec.rb:10"
    ))
    registry.add(RSpec::Undefined::Entry.new(
      kind: :declaration, description: "未確定", category: nil,
      location: "spec/y_spec.rb:5"
    ))
  end

  it "JSON を書き出す" do
    Tempfile.create(["rep", ".json"]) do |f|
      described_class.new(f.path).write
      data = JSON.parse(File.read(f.path))
      expect(data["count"]).to eq(2)
      expect(data["entries"][0]["matcher"]).to eq("be_undefined")
      expect(data["entries"][0]["category"]).to eq("boundary")
      expect(data["entries"][0]["actual"]).to eq(42)
      expect(data["entries"][1]["kind"]).to eq("declaration")
      expect(data["entries"][1]["category"]).to be_nil
    end
  end

  it "センチネル値を文字列化する" do
    Tempfile.create(["rep", ".json"]) do |f|
      described_class.new(f.path).write
      data = JSON.parse(File.read(f.path))
      expect(data["entries"][0]["expected"]).to eq("__any__")
    end
  end

  it "書き込み失敗時は stderr に警告し例外を上げない" do
    err = StringIO.new
    r = described_class.new("/nonexistent/dir/out.json", stderr: err)
    expect { r.write }.not_to raise_error
    expect(err.string).to include("rspec-undefined")
  end

  it "失敗時に tmp ファイルを残さない" do
    err = StringIO.new
    bad_path = "/nonexistent/dir/out.json"
    described_class.new(bad_path, stderr: err).write
    expect(Dir.glob("#{File.dirname(bad_path)}/*.tmp*")).to be_empty
  end
end

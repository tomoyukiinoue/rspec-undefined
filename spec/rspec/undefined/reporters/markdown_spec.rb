# frozen_string_literal: true

require "stringio"
require "tempfile"
require "rspec/undefined/entry"
require "rspec/undefined/registry"
require "rspec/undefined/reporters/markdown"

RSpec.describe RSpec::Undefined::Reporters::Markdown do
  let(:registry) { RSpec::Undefined::Registry.new }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    registry.add(RSpec::Undefined::Entry.new(
      kind: :matcher, matcher: "be_undefined", category: :boundary,
      expected: :__any__, actual: 42, matched: true,
      location: "spec/x_spec.rb:10"
    ))
    registry.add(RSpec::Undefined::Entry.new(
      kind: :declaration, description: "パイプ|含み",
      category: :order, location: "spec/y_spec.rb:5"
    ))
  end

  it "Markdown テーブルを書き出す" do
    Tempfile.create(["rep", ".md"]) do |f|
      described_class.new(f.path).write
      txt = File.read(f.path)
      expect(txt).to include("# Undefined spec items")
      expect(txt).to include("Total: 2")
      expect(txt).to include("| kind | matcher |")
      expect(txt).to include("| --- |")
      expect(txt).to include("spec/x_spec.rb:10")
    end
  end

  it "パイプをエスケープする" do
    Tempfile.create(["rep", ".md"]) do |f|
      described_class.new(f.path).write
      txt = File.read(f.path)
      expect(txt).to include("パイプ\\|含み")
    end
  end

  it "書き込み失敗時は stderr 警告のみ" do
    err = StringIO.new
    r = described_class.new("/nonexistent/dir/out.md", stderr: err)
    expect { r.write }.not_to raise_error
    expect(err.string).to include("rspec-undefined")
  end

  it "失敗時に tmp ファイルを残さない" do
    err = StringIO.new
    bad_path = "/nonexistent/dir/out.md"
    described_class.new(bad_path, stderr: err).write
    expect(Dir.glob("#{File.dirname(bad_path)}/*.tmp*")).to be_empty
  end
end

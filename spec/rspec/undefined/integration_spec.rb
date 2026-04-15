# frozen_string_literal: true

require "json"
require "fileutils"
require_relative "../../support/subprocess_runner"

RSpec.describe "rspec/undefined (integration)" do
  include SubprocessRunner

  it "require \"rspec/undefined\" 一行で全機能が使える" do
    src = <<~RUBY
      RSpec.describe "サンプル" do
        it "be_undefined (カテゴリ + expected)" do
          expect([3, 2, 1]).to be_undefined(:order, expected: match_array([1, 2, 3]))
        end
        undefined "削除時の挙動", category: :deletion
      end
    RUBY

    stdout, _err, status = run_spec_source_oneline(src)
    expect(status.exitstatus).to eq(0)
    expect(stdout).to match(/undefined: 2/)
    expect(stdout).to include("by category:")
  end

  it "RSPEC_UNDEFINED_STRICT=1 で example が fail する" do
    src = <<~RUBY
      RSpec.describe "S" do
        it "fails" do
          expect(42).to be_undefined
        end
      end
    RUBY
    _out, _err, status = run_spec_source_oneline(src, env: { "RSPEC_UNDEFINED_STRICT" => "1" })
    expect(status.exitstatus).to_not eq(0)
  end

  it "report_path 指定で JSON が書かれる" do
    out_path = File.expand_path("tmp/integration_out.json", Dir.pwd)
    FileUtils.mkdir_p(File.dirname(out_path))
    File.delete(out_path) if File.exist?(out_path)

    src = <<~RUBY
      RSpec::Undefined.configure do |c|
        c.report_path = #{out_path.inspect}
        c.report_format = :json
      end
      RSpec.describe "S" do
        it "x" do
          expect(0).to be_undefined(:boundary)
        end
      end
    RUBY

    _out, _err, status = run_spec_source_oneline(src)
    expect(status.exitstatus).to eq(0)
    expect(File.exist?(out_path)).to eq(true)
    data = JSON.parse(File.read(out_path))
    expect(data["count"]).to eq(1)
    expect(data["entries"][0]["category"]).to eq("boundary")
  end
end

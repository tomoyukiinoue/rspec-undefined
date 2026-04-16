# frozen_string_literal: true

require "rspec/undefined/configuration"
require "rspec/undefined/registry"
require "rspec/undefined/dsl"

require_relative "../../support/subprocess_runner"

RSpec.describe "RSpec::Undefined::DSL" do
  include SubprocessRunner

  describe "モジュール注入" do
    it "RSpec::Core::ExampleGroup に undefined クラスメソッドを追加する" do
      expect(RSpec::Core::ExampleGroup.singleton_class.ancestors).to include(RSpec::Undefined::DSL)
    end
  end

  describe "サブプロセス実行" do
    it "ブロックなしの undefined 宣言は pass する" do
      src = <<-RUBY
        RSpec.describe "X" do
          undefined "仕様未確定"
        end
      RUBY
      _out, _err, status = run_spec_source(src)
      expect(status.exitstatus).to eq(0)
    end

    it "ブロック付きの undefined は中で失敗しても pass する" do
      src = <<-RUBY
        RSpec.describe "X" do
          undefined "ブロック付き" do
            expect(1).to eq(2)
          end
        end
      RUBY
      _out, _err, status = run_spec_source(src)
      expect(status.exitstatus).to eq(0)
    end

    it "category: を受け取る" do
      src = <<-RUBY
        RSpec.describe "X" do
          undefined "状態遷移", category: :state_transition
        end
      RUBY
      _out, _err, status = run_spec_source(src)
      expect(status.exitstatus).to eq(0)
    end

    it "undefined に String category を渡すと ArgumentError" do
      src = <<-RUBY
        RSpec.describe "X" do
          undefined "説明", category: "str"
        end
      RUBY
      _out, _err, status = run_spec_source(src)
      expect(status.exitstatus).to_not eq(0)
    end

    it "strict モードでは undefined 宣言が fail する" do
      src = <<-RUBY
        RSpec.describe "X" do
          undefined "未確定"
        end
      RUBY
      _out, _err, status = run_spec_source(src, env: { "RSPEC_UNDEFINED_STRICT" => "1" })
      expect(status.exitstatus).to_not eq(0)
    end
  end
end

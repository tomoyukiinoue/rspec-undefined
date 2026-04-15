# rspec-undefined 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 「仕様が未確定」であることをテスト内で明示的に表現できる RSpec 拡張 gem を実装する。

**Architecture:** Registry（記録蓄積）+ Matchers/DSL（記録入り口）+ Formatter/Reporters（出力）の三層。通常は常にパス、`RSPEC_UNDEFINED_STRICT=1` のときは undefined 使用箇所をすべて fail。

**Tech Stack:** Ruby >= 2.2.6, rspec-core 3.x, RSpec::Matchers DSL。外部依存は rspec-core のみ。

**前提:** 設計書 `docs/design.md` を正とする。差異が生じたらそちらを優先して本計画を更新する。

---

## ファイル構成（全タスク完了後の状態）

```
lib/rspec/undefined.rb                     エントリ
lib/rspec/undefined/version.rb             既存
lib/rspec/undefined/configuration.rb       設定
lib/rspec/undefined/entry.rb               値オブジェクト
lib/rspec/undefined/registry.rb            記録蓄積
lib/rspec/undefined/matchers.rb            マッチャ集合
lib/rspec/undefined/dsl.rb                 ExampleGroup 注入
lib/rspec/undefined/formatter.rb           標準フォーマッタ
lib/rspec/undefined/reporters/json.rb      JSON 書き出し
lib/rspec/undefined/reporters/yaml.rb      YAML 書き出し
spec/rspec/undefined/configuration_spec.rb
spec/rspec/undefined/entry_spec.rb
spec/rspec/undefined/registry_spec.rb
spec/rspec/undefined/matchers_spec.rb
spec/rspec/undefined/dsl_spec.rb
spec/rspec/undefined/formatter_spec.rb
spec/rspec/undefined/reporters/json_spec.rb
spec/rspec/undefined/reporters/yaml_spec.rb
spec/support/subprocess_runner.rb          サブプロセスspec実行ヘルパ
rspec-undefined.gemspec                    更新
README.md                                  日本語化
.github/workflows/main.yml                 マトリクス
```

---

## Task 1: gemspec と初期コミット下準備

**Files:**
- Modify: `rspec-undefined.gemspec`
- Modify: `README.md`
- Create: `CHANGELOG.md`

- [ ] **Step 1: gemspec を実プロジェクトに合わせて書き換える**

`rspec-undefined.gemspec` を以下に置き換える:

```ruby
# frozen_string_literal: true

require_relative "lib/rspec/undefined/version"

Gem::Specification.new do |spec|
  spec.name = "rspec-undefined"
  spec.version = Rspec::Undefined::VERSION
  spec.authors = ["Tomoyuki INOUE"]
  spec.email = ["tomoyuki.inoue@gmail.com"]

  spec.summary = "「仕様が未確定」であることをテスト内で明示的に表現する RSpec 拡張"
  spec.description = "レガシーシステムから現行踏襲仕様を起こすために、未確定の値や振る舞いを " \
                     "テスト中で明示的に記録できるマッチャと DSL を提供する。"
  spec.homepage = "https://github.com/tomoyukiinoue/rspec-undefined"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.2.6"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rspec-core", ">= 3.0", "< 4"
end
```

- [ ] **Step 2: CHANGELOG.md を作る**

```markdown
# Changelog

## [Unreleased]

- 初版実装
```

- [ ] **Step 3: README.md を日本語で最小限に書く**

```markdown
# rspec-undefined

「仕様が未確定である」ことをテスト内で明示的に表現する RSpec 拡張です。

レガシーシステムから現行踏襲の仕様書を起こす作業で、「仕様が決まっていないのでテストが書けない」という問題を、「未確定であることをテストに書いて切り出す」ことで解決します。

## インストール

Gemfile に以下を追加してください。

```ruby
gem "rspec-undefined", git: "https://github.com/tomoyukiinoue/rspec-undefined.git"
```

## 使い方

`spec/spec_helper.rb` で require します。

```ruby
require "rspec/undefined"
```

### マッチャ

```ruby
expect(value).to be_undefined
expect(value).to be_undefined_nil_or_empty
expect(users.map(&:id)).to match_undefined_order([1, 2, 3])
expect(value).to undefined_value_of(eq(3))
```

### example 宣言

```ruby
undefined "削除時の順序は未確定"
undefined "検証内容あり" do
  expect(something).to eq(42)
end
```

### 厳格モード

環境変数 `RSPEC_UNDEFINED_STRICT=1` を付けると、undefined を使ったすべての example が fail します。

## ライセンス

MIT
```

- [ ] **Step 4: bundle install を流して lockfile を再生成**

Run: `bundle install`
Expected: 成功。`rspec-core` が解決される。

- [ ] **Step 5: コミット**

```bash
git add rspec-undefined.gemspec CHANGELOG.md README.md Gemfile.lock
git commit -m "chore: gemspec を実プロジェクトに合わせて更新し README を書く"
```

---

## Task 2: Configuration

**Files:**
- Create: `lib/rspec/undefined/configuration.rb`
- Test: `spec/rspec/undefined/configuration_spec.rb`

- [ ] **Step 1: 失敗するテストを書く**

`spec/rspec/undefined/configuration_spec.rb`:

```ruby
# frozen_string_literal: true

require "rspec/undefined/configuration"

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

  describe "#report_path / #report_format" do
    it "report_path の既定は nil" do
      expect(config.report_path).to be_nil
    end

    it "report_format の既定は :json" do
      expect(config.report_format).to eq(:json)
    end

    it ":yaml を代入できる" do
      config.report_format = :yaml
      expect(config.report_format).to eq(:yaml)
    end

    it "未知のフォーマットは ArgumentError" do
      expect { config.report_format = :xml }.to raise_error(ArgumentError, /report_format/)
    end
  end
end
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `bundle exec rspec spec/rspec/undefined/configuration_spec.rb`
Expected: LoadError（ファイル未存在）

- [ ] **Step 3: 最小実装**

`lib/rspec/undefined/configuration.rb`:

```ruby
# frozen_string_literal: true

module RSpec
  module Undefined
    class Configuration
      ALLOWED_FORMATS = [:json, :yaml].freeze
      TRUE_VALUES = %w[1 true yes].freeze

      attr_accessor :report_path
      attr_reader :report_format

      def initialize(env: ENV)
        @env = env
        @strict_explicit = nil
        @report_path = nil
        @report_format = :json
      end

      def strict?
        return @strict_explicit unless @strict_explicit.nil?
        v = @env["RSPEC_UNDEFINED_STRICT"]
        return false if v.nil?
        TRUE_VALUES.include?(v.to_s.downcase)
      end

      def strict=(value)
        @strict_explicit = value ? true : false
      end

      def report_format=(value)
        unless ALLOWED_FORMATS.include?(value)
          raise ArgumentError, "report_format must be one of #{ALLOWED_FORMATS.inspect}"
        end
        @report_format = value
      end
    end
  end
end
```

- [ ] **Step 4: テスト通過を確認**

Run: `bundle exec rspec spec/rspec/undefined/configuration_spec.rb`
Expected: PASS（全 8 例）

- [ ] **Step 5: コミット**

```bash
git add lib/rspec/undefined/configuration.rb spec/rspec/undefined/configuration_spec.rb
git commit -m "feat: Configuration を追加"
```

---

## Task 3: Entry

**Files:**
- Create: `lib/rspec/undefined/entry.rb`
- Test: `spec/rspec/undefined/entry_spec.rb`

- [ ] **Step 1: 失敗するテストを書く**

`spec/rspec/undefined/entry_spec.rb`:

```ruby
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
end
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `bundle exec rspec spec/rspec/undefined/entry_spec.rb`
Expected: LoadError

- [ ] **Step 3: 実装**

`lib/rspec/undefined/entry.rb`:

```ruby
# frozen_string_literal: true

module RSpec
  module Undefined
    class Entry
      ATTRS = [:kind, :matcher, :description, :expected, :actual,
               :matched, :location, :example_id].freeze

      attr_reader(*ATTRS)

      def initialize(attrs = {})
        ATTRS.each { |a| instance_variable_set("@#{a}", attrs[a]) }
      end

      def to_h
        ATTRS.each_with_object({}) { |a, h| h[a] = instance_variable_get("@#{a}") }
      end
    end
  end
end
```

Ruby 2.2.6 互換のため `Struct` の `keyword_init:` は使わず、素のクラスとハッシュ引数にしている。

- [ ] **Step 4: テスト通過を確認**

Run: `bundle exec rspec spec/rspec/undefined/entry_spec.rb`
Expected: PASS（2例）

- [ ] **Step 5: コミット**

```bash
git add lib/rspec/undefined/entry.rb spec/rspec/undefined/entry_spec.rb
git commit -m "feat: Entry 値オブジェクトを追加"
```

---

## Task 4: Registry

**Files:**
- Create: `lib/rspec/undefined/registry.rb`
- Test: `spec/rspec/undefined/registry_spec.rb`

- [ ] **Step 1: 失敗するテストを書く**

`spec/rspec/undefined/registry_spec.rb`:

```ruby
# frozen_string_literal: true

require "rspec/undefined/entry"
require "rspec/undefined/registry"

RSpec.describe RSpec::Undefined::Registry do
  subject(:registry) { described_class.new }

  let(:entry) do
    RSpec::Undefined::Entry.new(kind: :matcher, matcher: "be_undefined",
                                location: "spec/x.rb:1")
  end

  it "追加と取得" do
    registry.add(entry)
    expect(registry.all.size).to eq(1)
    expect(registry.all.first).to be(entry)
  end

  it "clear で空になる" do
    registry.add(entry)
    registry.clear
    expect(registry.all).to eq([])
  end

  it "スレッドセーフ" do
    threads = 20.times.map do
      Thread.new do
        10.times { registry.add(entry) }
      end
    end
    threads.each(&:join)
    expect(registry.all.size).to eq(200)
  end

  describe ".instance" do
    it "シングルトン" do
      expect(described_class.instance).to be(described_class.instance)
    end
  end
end
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `bundle exec rspec spec/rspec/undefined/registry_spec.rb`
Expected: LoadError

- [ ] **Step 3: 実装**

`lib/rspec/undefined/registry.rb`:

```ruby
# frozen_string_literal: true

require "thread"

module RSpec
  module Undefined
    class Registry
      def initialize
        @mutex = Mutex.new
        @entries = []
      end

      def add(entry)
        @mutex.synchronize { @entries << entry }
        entry
      end

      def all
        @mutex.synchronize { @entries.dup }
      end

      def clear
        @mutex.synchronize { @entries.clear }
      end

      @singleton_mutex = Mutex.new

      def self.instance
        @singleton_mutex.synchronize { @instance ||= new }
      end

      # テスト用に差し替え可能にする
      def self.reset!
        @singleton_mutex.synchronize { @instance = nil }
      end
    end
  end
end
```

- [ ] **Step 4: テスト通過を確認**

Run: `bundle exec rspec spec/rspec/undefined/registry_spec.rb`
Expected: PASS（4例）

- [ ] **Step 5: コミット**

```bash
git add lib/rspec/undefined/registry.rb spec/rspec/undefined/registry_spec.rb
git commit -m "feat: Registry を追加"
```

---

## Task 5: be_undefined マッチャ

**Files:**
- Create: `lib/rspec/undefined/matchers.rb`（この Task で新規作成、後続の Task で加筆）
- Create: `spec/rspec/undefined/matchers_spec.rb`

- [ ] **Step 1: 失敗するテストを書く**

`spec/rspec/undefined/matchers_spec.rb`:

```ruby
# frozen_string_literal: true

require "rspec/undefined/configuration"
require "rspec/undefined/entry"
require "rspec/undefined/registry"
require "rspec/undefined/matchers"

RSpec.describe "RSpec::Undefined::Matchers#be_undefined" do
  include RSpec::Undefined::Matchers

  let(:registry) { RSpec::Undefined::Registry.new }
  let(:config)   { RSpec::Undefined::Configuration.new(env: {}) }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    allow(RSpec::Undefined).to receive(:configuration).and_return(config)
  end

  it "常にマッチし Registry に記録する" do
    matcher = be_undefined
    expect(matcher.matches?(42)).to eq(true)
    expect(registry.all.size).to eq(1)
    entry = registry.all.first
    expect(entry.kind).to eq(:matcher)
    expect(entry.matcher).to eq("be_undefined")
    expect(entry.actual).to eq(42)
    expect(entry.expected).to eq(:__any__)
    expect(entry.matched).to eq(true)
  end

  it "strict モードでは matches? が false" do
    config.strict = true
    matcher = be_undefined
    expect(matcher.matches?(42)).to eq(false)
    expect(matcher.failure_message).to include("undefined")
  end
end
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `bundle exec rspec spec/rspec/undefined/matchers_spec.rb`
Expected: LoadError

- [ ] **Step 3: Matchers モジュールと be_undefined を実装**

`lib/rspec/undefined/matchers.rb`:

```ruby
# frozen_string_literal: true

require "rspec/undefined/entry"

module RSpec
  module Undefined
    module Matchers
      class BaseMatcher
        attr_reader :matcher_name, :actual, :expected_recorded

        def initialize(matcher_name)
          @matcher_name = matcher_name
          @expected_recorded = :__any__
        end

        def matches?(actual)
          @actual = actual
          matched = evaluate(actual)
          record(matched)
          !RSpec::Undefined.configuration.strict?
        end

        def does_not_match?(actual)
          # undefined は否定に使う意味がない。常に failure 扱いとする。
          @actual = actual
          false
        end

        def failure_message
          "undefined[#{matcher_name}] at #{location_summary}: expected=#{@expected_recorded.inspect} actual=#{@actual.inspect}"
        end

        def failure_message_when_negated
          "undefined matcher (#{matcher_name}) は否定形では使えません"
        end

        def description
          "は未確定仕様 (#{matcher_name}) である"
        end

        private

        def evaluate(_actual)
          true
        end

        def record(matched)
          RSpec::Undefined.registry.add(
            RSpec::Undefined::Entry.new(
              kind: :matcher,
              matcher: matcher_name,
              expected: @expected_recorded,
              actual: @actual,
              matched: matched,
              location: caller_location,
              example_id: current_example_id
            )
          )
        end

        def caller_location
          frame = caller_locations(1, 20).find { |l| l.path !~ /lib\/rspec\/undefined/ }
          frame ? "#{frame.path}:#{frame.lineno}" : nil
        end

        def current_example_id
          ex = RSpec.current_example rescue nil
          ex && ex.id
        end
      end

      class BeUndefined < BaseMatcher
        def initialize
          super("be_undefined")
        end
      end

      def be_undefined
        BeUndefined.new
      end
    end

    class << self
      def registry
        Registry.instance
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield configuration
      end
    end
  end
end
```

- [ ] **Step 4: テスト通過を確認**

Run: `bundle exec rspec spec/rspec/undefined/matchers_spec.rb`
Expected: PASS（2例）

- [ ] **Step 5: コミット**

```bash
git add lib/rspec/undefined/matchers.rb spec/rspec/undefined/matchers_spec.rb
git commit -m "feat: be_undefined マッチャを追加"
```

---

## Task 6: be_undefined_nil_or_empty

**Files:**
- Modify: `lib/rspec/undefined/matchers.rb`
- Modify: `spec/rspec/undefined/matchers_spec.rb`

- [ ] **Step 1: 失敗するテストを追加**

`spec/rspec/undefined/matchers_spec.rb` の末尾に追記:

```ruby
RSpec.describe "RSpec::Undefined::Matchers#be_undefined_nil_or_empty" do
  include RSpec::Undefined::Matchers

  let(:registry) { RSpec::Undefined::Registry.new }
  let(:config)   { RSpec::Undefined::Configuration.new(env: {}) }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    allow(RSpec::Undefined).to receive(:configuration).and_return(config)
  end

  it "nil は matched=true" do
    be_undefined_nil_or_empty.matches?(nil)
    expect(registry.all.first.matched).to eq(true)
  end

  it "空配列は matched=true" do
    be_undefined_nil_or_empty.matches?([])
    expect(registry.all.first.matched).to eq(true)
  end

  it "要素ありの配列は matched=false" do
    be_undefined_nil_or_empty.matches?([1])
    expect(registry.all.first.matched).to eq(false)
  end

  it "empty? を持たない値は matched=false" do
    be_undefined_nil_or_empty.matches?(42)
    expect(registry.all.first.matched).to eq(false)
  end

  it "通常モードでは matches? は true を返す" do
    expect(be_undefined_nil_or_empty.matches?([1])).to eq(true)
  end

  it "strict モードでは matches? が false" do
    config.strict = true
    expect(be_undefined_nil_or_empty.matches?([1])).to eq(false)
  end
end
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `bundle exec rspec spec/rspec/undefined/matchers_spec.rb`
Expected: NoMethodError: undefined method `be_undefined_nil_or_empty`

- [ ] **Step 3: 実装**

`lib/rspec/undefined/matchers.rb` の `BeUndefined` の下に追加:

```ruby
class BeUndefinedNilOrEmpty < BaseMatcher
  def initialize
    super("be_undefined_nil_or_empty")
    @expected_recorded = :__nil_or_empty__
  end

  private

  def evaluate(actual)
    return true if actual.nil?
    return actual.empty? if actual.respond_to?(:empty?)
    false
  end
end
```

同じモジュール内に:

```ruby
def be_undefined_nil_or_empty
  BeUndefinedNilOrEmpty.new
end
```

- [ ] **Step 4: テスト通過を確認**

Run: `bundle exec rspec spec/rspec/undefined/matchers_spec.rb`
Expected: PASS

- [ ] **Step 5: コミット**

```bash
git add lib/rspec/undefined/matchers.rb spec/rspec/undefined/matchers_spec.rb
git commit -m "feat: be_undefined_nil_or_empty マッチャを追加"
```

---

## Task 7: match_undefined_order

**Files:**
- Modify: `lib/rspec/undefined/matchers.rb`
- Modify: `spec/rspec/undefined/matchers_spec.rb`

- [ ] **Step 1: 失敗するテストを追加**

```ruby
RSpec.describe "RSpec::Undefined::Matchers#match_undefined_order" do
  include RSpec::Undefined::Matchers

  let(:registry) { RSpec::Undefined::Registry.new }
  let(:config)   { RSpec::Undefined::Configuration.new(env: {}) }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    allow(RSpec::Undefined).to receive(:configuration).and_return(config)
  end

  it "同じ要素・異なる順序なら matched=true" do
    match_undefined_order([1, 2, 3]).matches?([3, 1, 2])
    entry = registry.all.first
    expect(entry.matched).to eq(true)
    expect(entry.expected).to eq([1, 2, 3])
    expect(entry.actual).to eq([3, 1, 2])
  end

  it "要素が違えば matched=false" do
    match_undefined_order([1, 2, 3]).matches?([1, 2])
    expect(registry.all.first.matched).to eq(false)
  end

  it "比較不能値は matched=nil" do
    match_undefined_order([1, "a"]).matches?(["a", 1])
    expect(registry.all.first.matched).to be_nil
  end

  it "通常モードでは matches? は常に true" do
    expect(match_undefined_order([1]).matches?([2, 3])).to eq(true)
  end
end
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `bundle exec rspec spec/rspec/undefined/matchers_spec.rb`
Expected: NoMethodError

- [ ] **Step 3: 実装**

`matchers.rb` に追加:

```ruby
class MatchUndefinedOrder < BaseMatcher
  def initialize(expected)
    super("match_undefined_order")
    @expected = expected
    @expected_recorded = expected
  end

  private

  def evaluate(actual)
    return false unless actual.is_a?(Array) && @expected.is_a?(Array)
    return false if actual.size != @expected.size
    begin
      @expected.sort == actual.sort
    rescue ArgumentError, TypeError
      nil
    end
  end
end
```

```ruby
def match_undefined_order(expected)
  MatchUndefinedOrder.new(expected)
end
```

- [ ] **Step 4: テスト通過を確認**

Run: `bundle exec rspec spec/rspec/undefined/matchers_spec.rb`
Expected: PASS

- [ ] **Step 5: コミット**

```bash
git add lib/rspec/undefined/matchers.rb spec/rspec/undefined/matchers_spec.rb
git commit -m "feat: match_undefined_order マッチャを追加"
```

---

## Task 8: undefined_value_of

**Files:**
- Modify: `lib/rspec/undefined/matchers.rb`
- Modify: `spec/rspec/undefined/matchers_spec.rb`

- [ ] **Step 1: 失敗するテストを追加**

```ruby
RSpec.describe "RSpec::Undefined::Matchers#undefined_value_of" do
  include RSpec::Undefined::Matchers

  let(:registry) { RSpec::Undefined::Registry.new }
  let(:config)   { RSpec::Undefined::Configuration.new(env: {}) }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    allow(RSpec::Undefined).to receive(:configuration).and_return(config)
  end

  it "内側マッチャが通れば matched=true" do
    undefined_value_of(eq(3)).matches?(3)
    expect(registry.all.first.matched).to eq(true)
  end

  it "内側マッチャが落ちれば matched=false" do
    undefined_value_of(eq(3)).matches?(4)
    expect(registry.all.first.matched).to eq(false)
  end

  it "期待値に内側 description を記録する" do
    undefined_value_of(eq(3)).matches?(3)
    expect(registry.all.first.expected).to include("3")
  end

  it "通常モードでは常に matches? は true" do
    expect(undefined_value_of(eq(3)).matches?(4)).to eq(true)
  end
end
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `bundle exec rspec spec/rspec/undefined/matchers_spec.rb`

- [ ] **Step 3: 実装**

```ruby
class UndefinedValueOf < BaseMatcher
  def initialize(inner)
    super("undefined_value_of")
    @inner = inner
    @expected_recorded = describe_inner(inner)
  end

  private

  def evaluate(actual)
    @inner.matches?(actual)
  end

  def describe_inner(inner)
    if inner.respond_to?(:description)
      inner.description
    else
      inner.class.name
    end
  end
end
```

```ruby
def undefined_value_of(inner)
  UndefinedValueOf.new(inner)
end
```

- [ ] **Step 4: テスト通過を確認**

Run: `bundle exec rspec spec/rspec/undefined/matchers_spec.rb`
Expected: PASS

- [ ] **Step 5: コミット**

```bash
git add lib/rspec/undefined/matchers.rb spec/rspec/undefined/matchers_spec.rb
git commit -m "feat: undefined_value_of マッチャを追加"
```

---

## Task 8.5: カテゴリ対応

**目的:** すべての undefined 系記録に「仕様考慮漏れの類型」を示す Symbol カテゴリを付与できるようにする。挙動は変えず、記録とレポートのみに影響。

**Files:**
- Create: `lib/rspec/undefined/categories.rb`
- Modify: `lib/rspec/undefined/entry.rb`（`:category` 属性を追加）
- Modify: `lib/rspec/undefined/matchers.rb`（全マッチャでカテゴリ受付）
- Modify: `spec/rspec/undefined/entry_spec.rb`（category 属性の確認追加）
- Modify: `spec/rspec/undefined/matchers_spec.rb`（カテゴリ付きのテスト追加）

### Step 1: Categories 定数を追加

`lib/rspec/undefined/categories.rb`:

```ruby
# frozen_string_literal: true

module RSpec
  module Undefined
    module Categories
      STANDARD = [
        :boundary,
        :nil_or_empty,
        :uniqueness,
        :order,
        :datetime,
        :encoding,
        :rounding,
        :permission,
        :state_transition,
        :concurrency,
        :deletion,
        :retroactive,
        :idempotency
      ].freeze
    end
  end
end
```

### Step 2: Entry に `:category` 属性を追加

`lib/rspec/undefined/entry.rb` の `ATTRS` に `:category` を追加:

```ruby
ATTRS = [:kind, :matcher, :description, :category, :expected, :actual,
         :matched, :location, :example_id].freeze
```

`spec/rspec/undefined/entry_spec.rb` に以下を追加:

```ruby
it "category 属性を受け取る" do
  entry = described_class.new(kind: :matcher, category: :boundary)
  expect(entry.category).to eq(:boundary)
  expect(entry.to_h[:category]).to eq(:boundary)
end

it "category 未指定時は nil" do
  entry = described_class.new(kind: :declaration)
  expect(entry.category).to be_nil
end
```

### Step 3: BaseMatcher とファクトリをカテゴリ対応に

`lib/rspec/undefined/matchers.rb` の `BaseMatcher` を修正:

```ruby
class BaseMatcher
  attr_reader :matcher_name, :actual, :expected_recorded, :category

  def initialize(matcher_name, category: nil)
    @matcher_name = matcher_name
    @expected_recorded = :__any__
    @category = category
  end

  # ... matches?, failure_message 等は既存のまま ...

  private

  def record(matched)
    RSpec::Undefined.registry.add(
      RSpec::Undefined::Entry.new(
        kind: :matcher,
        matcher: matcher_name,
        category: @category,
        expected: @expected_recorded,
        actual: @actual,
        matched: matched,
        location: location_summary,
        example_id: current_example_id
      )
    )
  end
  # ...
end
```

各マッチャ:

```ruby
class BeUndefined < BaseMatcher
  def initialize(category = nil)
    super("be_undefined", category: category)
  end
end

class BeUndefinedNilOrEmpty < BaseMatcher
  def initialize(category = nil)
    super("be_undefined_nil_or_empty", category: category || :nil_or_empty)
    @expected_recorded = :__nil_or_empty__
  end
  # ...
end

class MatchUndefinedOrder < BaseMatcher
  def initialize(expected, category = :order)
    super("match_undefined_order", category)
    @expected = expected
    @expected_recorded = expected
  end
  # ...
end

class UndefinedValueOf < BaseMatcher
  def initialize(inner, category = nil)
    super("undefined_value_of", category)
    @inner = inner
    @expected_recorded = describe_inner(inner)
  end
  # ...
end

def be_undefined(category = nil)
  BeUndefined.new(category)
end

def be_undefined_nil_or_empty(category = nil)
  BeUndefinedNilOrEmpty.new(category)
end

def match_undefined_order(expected, category = :order)
  MatchUndefinedOrder.new(expected, category)
end

def undefined_value_of(inner, category = nil)
  UndefinedValueOf.new(inner, category)
end
```

※ `BaseMatcher#initialize` も `def initialize(matcher_name, category = nil)` の **位置引数** に揃える。`Symbol` / `String` どちらも category として受理する（型チェックなし）。

### Step 4: テストを追加

`spec/rspec/undefined/matchers_spec.rb` にカテゴリ付きの例を数例追加:

```ruby
it "be_undefined にカテゴリを渡すと Entry に記録される" do
  be_undefined(:boundary).matches?(100)
  expect(registry.all.first.category).to eq(:boundary)
end

it "be_undefined_nil_or_empty の既定カテゴリは :nil_or_empty" do
  be_undefined_nil_or_empty.matches?(nil)
  expect(registry.all.first.category).to eq(:nil_or_empty)
end

it "match_undefined_order の既定カテゴリは :order" do
  match_undefined_order([1,2]).matches?([2,1])
  expect(registry.all.first.category).to eq(:order)
end

it "match_undefined_order はカテゴリを上書きできる" do
  match_undefined_order([1,2], category: :deletion).matches?([1,2])
  expect(registry.all.first.category).to eq(:deletion)
end
```

### Step 5: エントリポイントで Categories を require

`lib/rspec/undefined.rb` は Task 13 で書き換える予定だが、Categories の require をそちらに仕込む。今は matchers.rb の冒頭に以下を入れておく:

```ruby
require "rspec/undefined/categories"
```

### Step 6: テスト通過を確認

Run: `bundle exec rspec spec/rspec/undefined/entry_spec.rb spec/rspec/undefined/matchers_spec.rb`
全 PASS を確認。

### Step 7: コミット

```bash
git add lib/rspec/undefined/categories.rb lib/rspec/undefined/entry.rb lib/rspec/undefined/matchers.rb spec/rspec/undefined/entry_spec.rb spec/rspec/undefined/matchers_spec.rb
git commit -m "feat: マッチャと Entry にカテゴリ対応を追加"
```

---

## Task 9: DSL (`undefined "..."`)

**Files:**
- Create: `lib/rspec/undefined/dsl.rb`
- Create: `spec/rspec/undefined/dsl_spec.rb`
- Create: `spec/support/subprocess_runner.rb`

- [ ] **Step 1: サブプロセスヘルパを作る**

`spec/support/subprocess_runner.rb`:

```ruby
# frozen_string_literal: true

require "open3"
require "tempfile"

module SubprocessRunner
  # spec ソース文字列を一時ファイルに書き、rspec を別プロセスで実行する
  def run_spec_source(source, env: {})
    Tempfile.create(["dsl_spec", ".rb"]) do |f|
      f.write(<<~RUBY + source)
        $LOAD_PATH.unshift(File.expand_path("#{Dir.pwd}/lib"))
        require "rspec/autorun"
        require "rspec/undefined"
      RUBY
      f.flush
      cmd = ["bundle", "exec", "rspec", f.path, "--format", "documentation"]
      stdout, stderr, status = Open3.capture3(env, *cmd)
      [stdout, stderr, status]
    end
  end
end
```

- [ ] **Step 2: 失敗するテストを書く**

`spec/rspec/undefined/dsl_spec.rb`:

```ruby
# frozen_string_literal: true

require "rspec/undefined/configuration"
require "rspec/undefined/registry"
require "rspec/undefined/dsl"

require_relative "../support/subprocess_runner"

RSpec.describe "RSpec::Undefined::DSL" do
  include SubprocessRunner

  it "ブロックなしの undefined 宣言は Registry に積まれ pass になる" do
    src = <<~RUBY
      RSpec.describe "X" do
        undefined "仕様未確定"
      end
    RUBY
    stdout, _err, status = run_spec_source(src)
    expect(status.exitstatus).to eq(0)
    expect(stdout).to match(/undefined/i)
  end

  it "ブロック付きの undefined は中で失敗しても pass になる" do
    src = <<~RUBY
      RSpec.describe "X" do
        undefined "ブロック付き" do
          expect(1).to eq(2)
        end
      end
    RUBY
    _out, _err, status = run_spec_source(src)
    expect(status.exitstatus).to eq(0)
  end

  it "strict モードでは undefined 宣言が fail になる" do
    src = <<~RUBY
      RSpec.describe "X" do
        undefined "未確定"
      end
    RUBY
    _out, _err, status = run_spec_source(src, env: { "RSPEC_UNDEFINED_STRICT" => "1" })
    expect(status.exitstatus).to_not eq(0)
  end
end
```

- [ ] **Step 3: テストが失敗することを確認**

Run: `bundle exec rspec spec/rspec/undefined/dsl_spec.rb`
Expected: LoadError または exitstatus 不一致

- [ ] **Step 4: 実装**

`lib/rspec/undefined/dsl.rb`:

```ruby
# frozen_string_literal: true

require "rspec/core"
require "rspec/undefined/entry"

module RSpec
  module Undefined
    module DSL
      def undefined(description, category: nil, &block)
        loc = caller_locations(1, 1).first
        location = loc ? "#{loc.path}:#{loc.lineno}" : nil
        example("[undefined] #{description}", undefined: true, undefined_category: category) do
          RSpec::Undefined.registry.add(
            RSpec::Undefined::Entry.new(
              kind: :declaration,
              description: description,
              category: category,
              location: location,
              example_id: RSpec.current_example && RSpec.current_example.id
            )
          )

          if RSpec::Undefined.configuration.strict?
            raise RSpec::Expectations::ExpectationNotMetError,
                  "undefined declaration (strict mode): #{description}"
          end

          if block
            begin
              instance_exec(&block)
            rescue RSpec::Expectations::ExpectationNotMetError
              # 通常モードではブロック内 failure を握り潰す
            end
          end
        end
      end
    end
  end
end

RSpec::Core::ExampleGroup.singleton_class.send(:include, RSpec::Undefined::DSL)
```

- [ ] **Step 5: テスト通過を確認**

Run: `bundle exec rspec spec/rspec/undefined/dsl_spec.rb`
Expected: PASS（3例）

- [ ] **Step 6: コミット**

```bash
git add lib/rspec/undefined/dsl.rb spec/rspec/undefined/dsl_spec.rb spec/support/subprocess_runner.rb
git commit -m "feat: undefined DSL を追加"
```

---

## Task 10: Formatter（stdout サマリ + 詳細）

**Files:**
- Create: `lib/rspec/undefined/formatter.rb`
- Create: `spec/rspec/undefined/formatter_spec.rb`

- [ ] **Step 1: 失敗するテストを書く**

`spec/rspec/undefined/formatter_spec.rb`:

```ruby
# frozen_string_literal: true

require "stringio"
require "rspec/undefined/entry"
require "rspec/undefined/registry"
require "rspec/undefined/formatter"

RSpec.describe RSpec::Undefined::Formatter do
  let(:io) { StringIO.new }
  let(:registry) { RSpec::Undefined::Registry.new }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    registry.add(RSpec::Undefined::Entry.new(
      kind: :matcher, matcher: "be_undefined",
      expected: :__any__, actual: 42, matched: true,
      location: "spec/x_spec.rb:10", description: nil
    ))
    registry.add(RSpec::Undefined::Entry.new(
      kind: :declaration, description: "順序未確定",
      location: "spec/y_spec.rb:5"
    ))
  end

  it "サマリ行を出力する" do
    described_class.new(io).dump_summary(nil)
    expect(io.string).to include("undefined: 2")
  end

  it "詳細リストを出力する" do
    described_class.new(io).dump_summary(nil)
    expect(io.string).to include("spec/x_spec.rb:10")
    expect(io.string).to include("spec/y_spec.rb:5")
    expect(io.string).to include("be_undefined")
    expect(io.string).to include("順序未確定")
  end

  it "0 件のときは何も出力しない" do
    registry.clear
    described_class.new(io).dump_summary(nil)
    expect(io.string).to eq("")
  end
end
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `bundle exec rspec spec/rspec/undefined/formatter_spec.rb`
Expected: LoadError

- [ ] **Step 3: 実装**

`lib/rspec/undefined/formatter.rb`:

```ruby
# frozen_string_literal: true

module RSpec
  module Undefined
    class Formatter
      def initialize(output = $stdout)
        @output = output
      end

      def dump_summary(_notification)
        entries = RSpec::Undefined.registry.all
        return if entries.empty?

        @output.puts
        @output.puts "Undefined spec items:"
        entries.each_with_index do |e, i|
          @output.puts format_entry(i + 1, e)
        end
        @output.puts
        @output.puts "undefined: #{entries.size}"
      end

      private

      def format_entry(index, entry)
        head = "  #{index}) [#{entry.kind}]"
        body =
          if entry.kind == :matcher
            "#{entry.matcher} expected=#{entry.expected.inspect} actual=#{entry.actual.inspect} matched=#{entry.matched.inspect}"
          else
            entry.description.to_s
          end
        "#{head} #{body} (#{entry.location})"
      end
    end
  end
end
```

- [ ] **Step 4: テスト通過を確認**

Run: `bundle exec rspec spec/rspec/undefined/formatter_spec.rb`
Expected: PASS（3例）

- [ ] **Step 5: コミット**

```bash
git add lib/rspec/undefined/formatter.rb spec/rspec/undefined/formatter_spec.rb
git commit -m "feat: 標準 Formatter を追加"
```

---

## Task 11: JSON Reporter

**Files:**
- Create: `lib/rspec/undefined/reporters/json.rb`
- Create: `spec/rspec/undefined/reporters/json_spec.rb`

- [ ] **Step 1: 失敗するテストを書く**

`spec/rspec/undefined/reporters/json_spec.rb`:

```ruby
# frozen_string_literal: true

require "json"
require "tempfile"
require "rspec/undefined/entry"
require "rspec/undefined/registry"
require "rspec/undefined/reporters/json"

RSpec.describe RSpec::Undefined::Reporters::Json do
  let(:registry) { RSpec::Undefined::Registry.new }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    registry.add(RSpec::Undefined::Entry.new(
      kind: :matcher, matcher: "be_undefined",
      expected: :__any__, actual: 42, matched: true,
      location: "spec/x_spec.rb:10"
    ))
  end

  it "JSON を書き出す" do
    Tempfile.create("rep.json") do |f|
      described_class.new(f.path).write
      data = JSON.parse(File.read(f.path))
      expect(data["count"]).to eq(1)
      expect(data["entries"].first["matcher"]).to eq("be_undefined")
      expect(data["entries"].first["actual"]).to eq(42)
    end
  end

  it "書き込み失敗時は stderr に警告し例外を上げない" do
    err = StringIO.new
    r = described_class.new("/nonexistent/dir/out.json", stderr: err)
    expect { r.write }.not_to raise_error
    expect(err.string).to include("rspec-undefined")
  end
end
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `bundle exec rspec spec/rspec/undefined/reporters/json_spec.rb`
Expected: LoadError

- [ ] **Step 3: 実装**

`lib/rspec/undefined/reporters/json.rb`:

```ruby
# frozen_string_literal: true

require "json"

module RSpec
  module Undefined
    module Reporters
      class Json
        def initialize(path, stderr: $stderr)
          @path = path
          @stderr = stderr
        end

        def write
          entries = RSpec::Undefined.registry.all
          payload = {
            "count" => entries.size,
            "entries" => entries.map { |e| serialize(e) }
          }
          File.write(@path, JSON.pretty_generate(payload))
        rescue SystemCallError, IOError => ex
          @stderr.puts "[rspec-undefined] failed to write #{@path}: #{ex.message}"
        end

        private

        def serialize(entry)
          h = entry.to_h
          h[:expected] = stringify_sentinel(h[:expected])
          h
        end

        def stringify_sentinel(value)
          case value
          when :__any__ then "__any__"
          when :__nil_or_empty__ then "__nil_or_empty__"
          else value
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: テスト通過を確認**

Run: `bundle exec rspec spec/rspec/undefined/reporters/json_spec.rb`
Expected: PASS（2例）

- [ ] **Step 5: コミット**

```bash
git add lib/rspec/undefined/reporters/json.rb spec/rspec/undefined/reporters/json_spec.rb
git commit -m "feat: JSON reporter を追加"
```

---

## Task 12: YAML Reporter

**Files:**
- Create: `lib/rspec/undefined/reporters/yaml.rb`
- Create: `spec/rspec/undefined/reporters/yaml_spec.rb`

- [ ] **Step 1: 失敗するテストを書く**

`spec/rspec/undefined/reporters/yaml_spec.rb`:

```ruby
# frozen_string_literal: true

require "yaml"
require "tempfile"
require "rspec/undefined/entry"
require "rspec/undefined/registry"
require "rspec/undefined/reporters/yaml"

RSpec.describe RSpec::Undefined::Reporters::Yaml do
  let(:registry) { RSpec::Undefined::Registry.new }

  before do
    allow(RSpec::Undefined).to receive(:registry).and_return(registry)
    registry.add(RSpec::Undefined::Entry.new(
      kind: :declaration, description: "順序未確定",
      location: "spec/x_spec.rb:10"
    ))
  end

  it "YAML を書き出す" do
    Tempfile.create(["rep", ".yml"]) do |f|
      described_class.new(f.path).write
      data = YAML.safe_load(File.read(f.path), permitted_classes: [Symbol])
      expect(data["count"]).to eq(1)
      expect(data["entries"].first["description"]).to eq("順序未確定")
    end
  end
end
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `bundle exec rspec spec/rspec/undefined/reporters/yaml_spec.rb`

- [ ] **Step 3: 実装**

`lib/rspec/undefined/reporters/yaml.rb`:

```ruby
# frozen_string_literal: true

require "yaml"

module RSpec
  module Undefined
    module Reporters
      class Yaml
        def initialize(path, stderr: $stderr)
          @path = path
          @stderr = stderr
        end

        def write
          entries = RSpec::Undefined.registry.all
          payload = {
            "count" => entries.size,
            "entries" => entries.map { |e| stringify_keys(e.to_h) }
          }
          File.write(@path, YAML.dump(payload))
        rescue SystemCallError, IOError => ex
          @stderr.puts "[rspec-undefined] failed to write #{@path}: #{ex.message}"
        end

        private

        def stringify_keys(hash)
          hash.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
        end
      end
    end
  end
end
```

- [ ] **Step 4: テスト通過を確認**

Run: `bundle exec rspec spec/rspec/undefined/reporters/yaml_spec.rb`
Expected: PASS

- [ ] **Step 5: コミット**

```bash
git add lib/rspec/undefined/reporters/yaml.rb spec/rspec/undefined/reporters/yaml_spec.rb
git commit -m "feat: YAML reporter を追加"
```

---

## Task 13: エントリ point の統合

**Files:**
- Modify: `lib/rspec/undefined.rb`
- Create: `spec/rspec/undefined/integration_spec.rb`

- [ ] **Step 1: 統合テストを書く**

`spec/rspec/undefined/integration_spec.rb`:

```ruby
# frozen_string_literal: true

require "json"
require "fileutils"
require_relative "../support/subprocess_runner"

RSpec.describe "rspec/undefined (integration)" do
  include SubprocessRunner

  it "マッチャと DSL を使い、サマリ行が出力される" do
    src = <<~RUBY
      RSpec.describe "サンプル" do
        it "be_undefined" do
          expect(42).to be_undefined
        end

        it "match_undefined_order" do
          expect([3, 2, 1]).to match_undefined_order([1, 2, 3])
        end

        undefined "削除時の挙動"
      end
    RUBY

    stdout, _err, status = run_spec_source(src)
    expect(status.exitstatus).to eq(0)
    expect(stdout).to match(/undefined: 3/)
  end

  it "RSPEC_UNDEFINED_STRICT=1 で example が fail する" do
    src = <<~RUBY
      RSpec.describe "S" do
        it "fails" do
          expect(42).to be_undefined
        end
      end
    RUBY

    _out, _err, status = run_spec_source(src, env: { "RSPEC_UNDEFINED_STRICT" => "1" })
    expect(status.exitstatus).to_not eq(0)
  end

  it "report_path 指定で JSON が書かれる" do
    out_path = File.expand_path("tmp/out_spec.json", Dir.pwd)
    FileUtils.mkdir_p(File.dirname(out_path))
    File.delete(out_path) if File.exist?(out_path)

    src = <<~RUBY
      RSpec::Undefined.configure do |c|
        c.report_path = #{out_path.inspect}
        c.report_format = :json
      end
      RSpec.describe "S" do
        it "x" do
          expect(0).to be_undefined
        end
      end
    RUBY

    _out, _err, status = run_spec_source(src)
    expect(status.exitstatus).to eq(0)
    expect(File.exist?(out_path)).to eq(true)
    data = JSON.parse(File.read(out_path))
    expect(data["count"]).to eq(1)
  end
end
```

`spec/spec_helper.rb` に以下を追加（必要なら）:

```ruby
require "json"
require "fileutils"
```

- [ ] **Step 2: テストが失敗することを確認**

Run: `bundle exec rspec spec/rspec/undefined/integration_spec.rb`
Expected: サマリ行が出ない、または require 失敗

- [ ] **Step 3: エントリポイント実装**

`lib/rspec/undefined.rb` を書き換える:

```ruby
# frozen_string_literal: true

require "rspec/core"
require "rspec/undefined/version"
require "rspec/undefined/configuration"
require "rspec/undefined/entry"
require "rspec/undefined/registry"
require "rspec/undefined/matchers"
require "rspec/undefined/dsl"
require "rspec/undefined/formatter"
require "rspec/undefined/reporters/json"
require "rspec/undefined/reporters/yaml"

module RSpec
  module Undefined
    class Error < StandardError; end
  end
end

RSpec.configure do |rspec|
  rspec.include RSpec::Undefined::Matchers

  rspec.before(:suite) do
    RSpec::Undefined.registry.clear
  end

  rspec.after(:suite) do
    io = $stdout
    RSpec::Undefined::Formatter.new(io).dump_summary(nil)

    cfg = RSpec::Undefined.configuration
    if cfg.report_path
      reporter =
        case cfg.report_format
        when :json then RSpec::Undefined::Reporters::Json.new(cfg.report_path)
        when :yaml then RSpec::Undefined::Reporters::Yaml.new(cfg.report_path)
        end
      reporter.write if reporter
    end
  end
end
```

- [ ] **Step 4: テスト通過を確認**

Run: `bundle exec rspec spec/rspec/undefined/integration_spec.rb`
Expected: PASS（3例）

- [ ] **Step 5: 全テスト一括実行**

Run: `bundle exec rspec`
Expected: 全 PASS

- [ ] **Step 6: コミット**

```bash
git add lib/rspec/undefined.rb spec/rspec/undefined/integration_spec.rb spec/spec_helper.rb
git commit -m "feat: エントリポイントと RSpec.configure フックを統合"
```

---

## Task 14: 既存 scaffold spec を実要件に置き換える

**Files:**
- Modify: `spec/rspec/undefined_spec.rb`

- [ ] **Step 1: scaffold の失敗テストを削除し、バージョン存在確認のみ残す**

`spec/rspec/undefined_spec.rb`:

```ruby
# frozen_string_literal: true

RSpec.describe RSpec::Undefined do
  it "バージョン番号を持つ" do
    expect(RSpec::Undefined::VERSION).not_to be_nil
  end

  it "Registry シングルトンを返す" do
    expect(RSpec::Undefined.registry).to be(RSpec::Undefined.registry)
  end

  it "Configuration を configure で設定できる" do
    RSpec::Undefined.configure { |c| c.report_format = :yaml }
    expect(RSpec::Undefined.configuration.report_format).to eq(:yaml)
    RSpec::Undefined.configure { |c| c.report_format = :json }
  end
end
```

- [ ] **Step 2: 全テストを実行**

Run: `bundle exec rspec`
Expected: 全 PASS

- [ ] **Step 3: コミット**

```bash
git add spec/rspec/undefined_spec.rb
git commit -m "test: scaffold の仮テストを実仕様に置き換え"
```

---

## Task 15: CI マトリクス

**Files:**
- Modify: `.github/workflows/main.yml`

- [ ] **Step 1: 既存 workflow を確認**

Run: `cat .github/workflows/main.yml`

- [ ] **Step 2: マトリクス構成に書き換える**

`.github/workflows/main.yml`:

```yaml
name: CI

on:
  push:
    branches: [main, master]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        ruby:
          - "2.7"
          - "3.1"
          - "3.3"
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby }}
          bundler-cache: true
      - name: Run tests
        run: bundle exec rspec
```

strict モードの挙動は `integration_spec` 内でサブプロセスを起動して検証しているため、CI ジョブ自体を strict で回す必要はない。

Ruby 2.2.6 は GitHub Actions の `ruby/setup-ruby` で入手困難なため CI では外し、手元テストの対象にとどめる。

- [ ] **Step 3: コミット**

```bash
git add .github/workflows/main.yml
git commit -m "ci: テストマトリクスを整備"
```

---

## Task 16: README 拡充とサンプル

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 使用例を追加**

README.md に以下のセクションを追記（既存セクションを壊さないこと）:

```markdown
## 出力例

```
Undefined spec items:
  1) [matcher] be_undefined expected=:__any__ actual=42 matched=true (spec/user_spec.rb:10)
  2) [declaration] 削除時の順序は未確定 (spec/user_spec.rb:25)

undefined: 2
```

## 設定

```ruby
RSpec::Undefined.configure do |c|
  c.strict        = ENV["CI"] == "true"  # 明示代入は環境変数より優先
  c.report_path   = "tmp/undefined.json"
  c.report_format = :json                 # :json | :yaml
end
```

## 推奨運用

1. レガシー仕様書の起こし作業中は通常モードで未確定を貯める
2. 定期的にレポートを見て仕様確定を進める
3. ほぼ確定したら CI で `RSPEC_UNDEFINED_STRICT=1` を有効にし、新規の undefined 混入を防ぐ
```

- [ ] **Step 2: コミット**

```bash
git add README.md
git commit -m "docs: 出力例と推奨運用を README に追記"
```

---

## 完了基準

- [ ] `bundle exec rspec` が 全 PASS
- [ ] `RSPEC_UNDEFINED_STRICT=1 bundle exec rspec spec/rspec/undefined/integration_spec.rb` で strict 用 example が想定通り fail
- [ ] `report_path` 指定で JSON / YAML ファイルが生成される
- [ ] README が日本語で最新の使用方法を反映している
- [ ] CI が少なくとも Ruby 2.7 / 3.1 / 3.3 で緑

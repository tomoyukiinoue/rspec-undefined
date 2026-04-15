# rspec-undefined 設計書

作成日: 2026-04-15
対象: `rspec-undefined` gem

## 1. 目的

レガシーシステムから現行踏襲の仕様書を起こす作業において、「仕様が決まっていないためテストが書けない」という詰まりを解消する。

本 gem は「仕様が決まっていないこと」をテスト内で **明示的に宣言できる手段** を提供し、テストの作成作業と仕様確定作業を分離できるようにする。

非目標:
- 汎用的なテストフレームワーク拡張ではない。「未確定であることを記録する」ことに特化する。
- 仕様確定を支援する自動推論や値生成は行わない。

## 2. 前提・対象環境

- Ruby: `>= 2.2.6`（レガシーシステムに追従）
- RSpec: `rspec-core 3.x` の公開 API のみに依存
- Rails: 4.0.x 以上の環境でも動作すること（Railtie には直接依存しない）
- 公開範囲: まずは個人の Private GitHub リポジトリで管理。RubyGems 公開は当面行わない。

レガシー互換のため以下を避ける:
- `Struct` の `keyword_init:`（2.5+）
- 右代入、パターンマッチ、`filter_map` 等、2.2 に存在しない構文・メソッド

## 3. スコープ（機能一覧）

### 3.1 マッチャ

マッチャは `be_undefined` 一本に統一する。第 1 引数で `Symbol` カテゴリ／内側マッチャ／無指定を切り替える。

| 呼び出し | 意味 |
|---|---|
| `be_undefined` | 値自体が不定。カテゴリなし |
| `be_undefined(:order)` | カテゴリのみ指定 |
| `be_undefined(eq(3))` | 内側マッチャで評価（カテゴリなし） |
| `be_undefined(eq(3), :rounding)` | 内側マッチャ + カテゴリ |

第 1 引数の型で判別: `Symbol` はカテゴリ、`matches?` に応答するオブジェクトは内側マッチャ、`nil` は何もなし。カテゴリと内側マッチャを両方指定する場合は `be_undefined(matcher, :category)` の順。

### 3.2 DSL（example レベルの宣言）

```ruby
undefined "削除時の順序は未確定"
undefined "..." do
  # 任意の検証を書いてもよい（記録のみ、失敗は基本無視）
end
```

### 3.3 レポート

- テスト実行末尾の **stdout サマリ**（例: `↑ 3 undefined`）
- **詳細リスト**（ファイル:行、説明、期待値、実値）
- **JSON / YAML リポート** のファイル出力（設定時のみ）
- **カスタムフォーマッタ** `RSpec::Undefined::Formatter` としても提供

### 3.4 厳格モード

- `ENV["RSPEC_UNDEFINED_STRICT"]` が `"1" | "true" | "yes"` のとき有効
- **有効時: undefined を使った全箇所を example 失敗にする**
- CI では strict、ローカル開発では寛容、のような切り替え運用を想定

### 3.5 カテゴリ（仕様考慮漏れの類型）

マッチャと DSL はオプションの **カテゴリ定数**（Symbol）を受け取れる。カテゴリは記録のみに使われ（挙動を変えない）、レポートで集計・分類される。利用者は任意のシンボルを渡せるが、標準カテゴリを以下に定義する。

| カテゴリ | 対象例 |
|---|---|
| `:boundary` | 上限/下限・最大件数・桁数・文字数・期間 |
| `:nil_or_empty` | 0 件・null・空文字・未入力 |
| `:uniqueness` | 一意制約・同名登録・同時登録 |
| `:order` | 並び順・ソート規則 |
| `:datetime` | 日時・タイムゾーン・和暦/西暦・うるう年/秒 |
| `:encoding` | 文字コード・絵文字・サロゲートペア・半角/全角 |
| `:rounding` | 金額丸め（四捨五入/銀行丸め）・通貨・税計算順序 |
| `:permission` | 権限境界（閲覧/編集/削除・代理操作） |
| `:state_transition` | 状態遷移（キャンセル後再操作・途中離脱・タイムアウト復帰） |
| `:concurrency` | 楽観/悲観ロック・同時編集コンフリクト |
| `:deletion` | 物理削除 vs 論理削除・削除済み参照 |
| `:retroactive` | マスタ変更遡及（過去データ表示は旧値か新値か） |
| `:idempotency` | 外部連携（リトライ・重複実行防止） |

定数集は `RSpec::Undefined::Categories::STANDARD`（配列）として公開。**カテゴリは `Symbol` のみを受理する**（表記ゆれ・集計困難を避けるため）。プロジェクト固有の分類は事前に **登録** してから使う:

```ruby
RSpec::Undefined.configure do |c|
  c.register_categories :invoice_rounding, :legacy_auth
end
# または
RSpec::Undefined::Categories.register(:invoice_rounding)
```

登録された値は `Categories.all` (= `STANDARD + registered`) に含まれる。`Categories.known?(v)` で判定できる。`Symbol` 以外（`String` 等）を category 引数に渡した場合は `ArgumentError` を raise。Formatter は集計時に未登録（`!known?`）のカテゴリ名に `*` マーカーを付けて表示し、`register` 忘れに気付けるようにする。

## 4. アーキテクチャ

### 4.1 モジュール構成

```
lib/rspec/undefined.rb                … エントリ（require 集約と RSpec.configure 仕込み）
lib/rspec/undefined/version.rb        … 既存
lib/rspec/undefined/configuration.rb  … 設定（strict / report_path / report_format）
lib/rspec/undefined/entry.rb          … 1 件の記録（値オブジェクト）
lib/rspec/undefined/registry.rb       … 記録蓄積（Mutex 付きシングルトン）
lib/rspec/undefined/matchers.rb       … 4 種のマッチャ定義
lib/rspec/undefined/dsl.rb            … undefined "..." を ExampleGroup に注入
lib/rspec/undefined/formatter.rb      … 標準フォーマッタ（stdout サマリ/詳細）
lib/rspec/undefined/reporters/json.rb … JSON 書き出し
lib/rspec/undefined/reporters/yaml.rb … YAML 書き出し
```

### 4.2 責務

- **Configuration**: 設定値の保持。`ENV` 参照も担う
- **Registry**: 登録・全件取得・クリア。プロセスグローバルで `Mutex` 保護
- **Matchers / DSL**: 使用者の入り口。呼ばれたら `Entry` を作って Registry に追加
- **Formatter**: RSpec の notification フックで stdout に整形出力
- **Reporters**: `after(:suite)` で起動し、`report_path` 設定時のみ書き出し

### 4.3 ロード戦略

`require "rspec/undefined"` のみで:

1. `RSpec::Matchers` へマッチャを define
2. `RSpec::Core::ExampleGroup` に `undefined` クラスメソッドを注入
3. `RSpec.configure` で `before(:suite)` クリア、`after(:suite)` で Formatter/Reporters 起動

ユーザーは `spec_helper.rb` に `require "rspec/undefined"` 一行追加すればよい。

## 5. データ構造

### Entry

```ruby
# 概念定義（2.2 互換のため keyword_init は使わない）
Entry = Struct.new(
  :kind,         # :matcher | :declaration
  :matcher,      # "be_undefined" 等。declaration のときは nil
  :description,  # 宣言文字列（任意）
  :category,     # カテゴリ Symbol（:boundary, :timezone 等）。未指定は nil
  :expected,     # 期待値（なければセンチネル :__any__ や :__nil_or_empty__）
  :actual,       # 実値（declaration のときは nil）
  :matched,      # true / false / nil（内部評価の結果）
  :location,     # "spec/foo_spec.rb:42"
  :example_id    # RSpec example の id
)
```

`matched` は strict モードでの失敗判定には使わない（strict 時はすべて失敗）。
レポート上で「期待値と実値のズレ」を可視化するためだけに保持する。

### Registry

- シングルトン: `RSpec::Undefined::Registry.instance`
- 操作: `add(entry)` / `all` / `clear`
- 並列テスト実行（`parallel_tests` 等）では **プロセスごとの Registry** に閉じる

## 6. マッチャ仕様

| 呼び出し | expected 記録 | actual 記録 | matched の評価 |
|---|---|---|---|
| `be_undefined` | `:__any__` | 実値 | 常に true |
| `be_undefined(:cat)` | `:__any__` | 実値 | 常に true（category=:cat） |
| `be_undefined(inner)` | `inner.description` | 実値 | `inner.matches?(actual)` |
| `be_undefined(inner, :cat)` | `inner.description` | 実値 | `inner.matches?(actual)` |

カテゴリは `Symbol` のみ受理。`String` 等は `ArgumentError`。

使用例:

```ruby
expect(x).to be_undefined                      # カテゴリなし
expect(x).to be_undefined(:boundary)           # 標準カテゴリ
expect(x).to be_undefined(:invoice_rounding)   # 事前登録したカスタムカテゴリ
expect(users.map(&:id)).to be_undefined(match_array([1,2,3]), :order)
expect(x).to be_undefined(eq(3), :rounding)
```

共通仕様:

- 通常モードでは `matches?` は **常に true** を返す（テストは必ずパス）
- **strict モードでは `matches?` は常に false**（3.3 の (b) 方針。すべての undefined 箇所を failure にする）
- `failure_message` は strict 時のみ用いられ、`kind / matcher / expected / actual / matched` を整形表示

## 7. DSL 仕様

```ruby
undefined "削除時の順序は未確定"                                  # カテゴリなし
undefined "キャンセル後の再操作未定", category: :state_transition  # 標準カテゴリ
undefined "独自観点", category: "マイ分類"                        # カスタム文字列カテゴリ
undefined "..." do ... end                                         # ブロック
undefined "冪等性", category: :idempotency do ... end             # カテゴリ + ブロック
```

シグネチャは `undefined(description, category: nil, &block)`。第 1 引数は常に説明（String）。カテゴリは `category:` キーワード引数で指定し、`Symbol` / `String` どちらも受ける。

- `ExampleGroup.undefined(desc, &block)` として注入
- 内部で `example(desc, :undefined) { ... }` 相当を生成
- `metadata[:undefined] = true` を付与
- strict 無効時:
  - ブロックなし → 空の example として pass。Registry へ declaration として記録
  - ブロックあり → ブロックを実行するが、内部の expectation 失敗は捕捉して例外を呑み、記録のみ（example は pass）
  - いずれも RSpec の `pending` / `skip` カテゴリには入れない（`undefined` は独立カテゴリ）
- strict 有効時: 常に example を fail させる（ブロック有無にかかわらず）

## 8. データフロー

```
[test run]
  │
  ├─ マッチャ呼び出し
  │    → Registry.add(Entry(kind: :matcher, ...))
  │
  ├─ undefined "..." 宣言
  │    → Registry.add(Entry(kind: :declaration, ...))
  │
  ├─ strict モード
  │    ├─ true  → 対応マッチャ/DSL が example を failure にする
  │    └─ false → 常に pass（記録のみ）
  │
[after(:suite)]
  │
  ├─ Formatter#dump_summary
  │    → stdout に サマリ + 詳細
  │
  └─ Configuration.report_path 設定時
       → JSON or YAML をファイル書き出し
```

## 9. 設定 API

```ruby
RSpec::Undefined.configure do |c|
  c.strict       = ENV["RSPEC_UNDEFINED_STRICT"] =~ /\A(1|true|yes)\z/i ? true : false
  c.report_path  = nil          # 例: "tmp/undefined_report.json"
  c.report_format = :json       # :json | :yaml
end
```

- `configure` ブロックを呼ばなければ、**環境変数の読取のみ** 行う既定動作
- `report_path` 未指定ならファイル出力は行わず、stdout サマリのみ

## 10. エラー処理

- **Registry 追加失敗**: 例外は握りつぶさず raise
- **Reporter 書き出し失敗**: stderr に警告を出し、スイートの結果は壊さない
- **比較不能値**: `match_undefined_order` で `sort` 不可時は `matched = nil`
- **RSpec 未ロード**: `require "rspec/undefined"` 時に RSpec 未定義なら `LoadError`

## 11. テスト戦略

- **ユニット**: `Registry` / `Configuration` / `Entry` / 各 `Reporter` を純粋 Ruby で単体テスト
- **マッチャ**: `it` 内で各マッチャを呼び、Registry の内容と返り値を検証
- **DSL**: `undefined "..."` を含む spec ファイルを `RSpec::Core::Runner.run` またはサブプロセスで実行し、結果を検証
- **Formatter**: notification オブジェクトをスタブして `dump_summary` の出力文字列を検証
- **strict モード**: `ENV` を差し替えてサブプロセス実行し、終了コードと件数を検証
- **CI マトリクス**:
  - Ruby 2.2.6 / 2.7 / 3.1 / 3.3
  - rspec-core 3.x の代表的なマイナー（3.0 / 3.12 相当）

## 12. 配布・公開

- 当面は Private GitHub（`tomoyukiinoue/rspec-undefined`）で管理
- `Gemfile` で `git:` 指定による導入を想定
- `gemspec`:
  - `required_ruby_version = ">= 2.2.6"`
  - `allowed_push_host` はメタデータから削除（公開しない）
  - `add_dependency "rspec-core", ">= 3.0", "< 4"`

## 13. 未決事項

なし（2026-04-15 時点）。

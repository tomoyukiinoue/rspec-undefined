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
expect(value).to be_undefined(:boundary)
expect(users.map(&:id)).to be_undefined(:order, expected: match_array([1, 2, 3]))
expect(value).to be_undefined(eq(3), :rounding)
```

### example 宣言

```ruby
undefined "削除時の順序は未確定"
undefined "キャンセル後の再操作", category: :state_transition
undefined "検証内容あり" do
  expect(something).to eq(42)
end
```

### 厳格モード

環境変数 `RSPEC_UNDEFINED_STRICT=1` を付けると、undefined を使ったすべての example が fail します。

## 出力例

テスト実行末尾に次のような要約が出力されます。

```
Undefined spec items:
  1) [matcher] {boundary} be_undefined expected=:__any__ actual=100 matched=true (spec/user_spec.rb:12)
  2) [declaration] {deletion} 削除時の挙動は未確定 (spec/user_spec.rb:30)

undefined: 2
by category:
  boundary: 1
  deletion: 1
```

## カテゴリ

「仕様考慮漏れ」の類型を Symbol カテゴリとして指定できます。標準カテゴリは 13 種類:

`:boundary`, `:nil_or_empty`, `:uniqueness`, `:order`, `:datetime`, `:encoding`, `:rounding`, `:permission`, `:state_transition`, `:concurrency`, `:deletion`, `:retroactive`, `:idempotency`

プロジェクト固有のカテゴリは `register_categories` で追加できます:

```ruby
RSpec::Undefined.configure do |c|
  c.register_categories :invoice_rounding, :legacy_auth
end

expect(total).to be_undefined(:invoice_rounding, expected: 1000)
```

未登録の Symbol を渡すと Formatter で `*` マーカー付きで表示され、登録忘れに気付けます。

## 設定

```ruby
RSpec::Undefined.configure do |c|
  c.report_path   = "tmp/undefined.json"
  c.report_format = :json                 # :json | :yaml
  c.register_categories :my_cat
end
```

## 推奨運用

1. レガシー仕様書の起こし作業中は通常モードで未確定を貯める
2. 定期的にレポートを見て仕様確定を進める
3. ほぼ確定したら CI で `RSPEC_UNDEFINED_STRICT=1` を有効にし、新規の未確定混入を防ぐ

## ライセンス

MIT

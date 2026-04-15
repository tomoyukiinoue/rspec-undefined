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

# rspec-undefined

<table>
  <thead>
    <tr>
      <th align="center"><a href="README.md">English</a></th>
      <th align="center">日本語</th>
    </tr>
  </thead>
</table>

「仕様が未確定である」ことをテスト内で明示的に表現する RSpec 拡張です。

AI でテストコードは現実的に書けるようになりましたが、仕様が未定義だったり振る舞いが不定だったりすると、AI でもテストは書けません。結局のところ、仕様を意思決定するのは人間の仕事として残ります。

レガシーシステムから現行踏襲の仕様書を起こす作業で、「仕様が決まっていないのでテストが書けない」という問題を、「未確定であることをテストに書いて切り出す」ことで解決します。

## コンセプト

「AIがテストを書く」と「人間が仕様を決める」という責任を別々のタイミングで全うできる方法として作りました。

- **現状の挙動はテストに固定する**（AI が書ける）
- **でもそれが正しい仕様かは未確定**、という印を `be_undefined` で残す
- **未確定はレポートに集計される** → そのまま論点リストになる
- **正しい仕様を決めるのは、後でヒューマンがやる**

詳しいコンセプトはこちらの記事で書いています: <https://zenn.dev/tokium_dev/articles/0b426c6d002e3e>

## インストール

Gemfile に以下を追加してください。

```ruby
gem "rspec-undefined", "~> 0.1.1"
```

## 使い方

`spec/spec_helper.rb` で require します。

```ruby
require "rspec/undefined"
```

### マッチャ

```ruby
expect(value).to be_undefined                                   # カテゴリなし
expect(value).to be_undefined(:boundary)                        # カテゴリのみ
expect(total).to be_undefined(:boundary, expected: 100)         # 暫定仕様の期待値（== 比較）
expect(users.map(&:id)).to be_undefined(:order, expected: match_array([1, 2, 3])) # Matcher 評価
expect(value).to be_undefined(eq(3), :rounding)                 # 内側マッチャ + カテゴリ
```

`expected:` キーワードに生値を渡すと `==` で比較され、RSpec マッチャを渡すと `matches?` で評価されます。値は記録だけされ（通常モードでは常に pass）、レポートで現状値とのズレを確認できます。

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
  c.report_format = :json                 # :json | :yaml | :csv | :markdown
  c.register_categories :my_cat
end
```

## strict モードと DSL の関係

`RSPEC_UNDEFINED_STRICT=1` を有効にすると以下の箇所が example 失敗になります:

- `be_undefined`（すべての形式）を呼んだ example
- `undefined "..."` / `undefined "...", category: :sym` で宣言した example（ブロック有無にかかわらず）

strict モード時、`undefined` DSL の**ブロックは実行されず、即座に fail します**。ブロック内の補助検証は通常モードでのみ走ります。

## require の副作用について

`require "rspec/undefined"` を実行すると、`RSpec.configure` の `before(:suite)` / `after(:suite)` フックが登録され、`RSpec::Matchers` に `be_undefined` がミックスインされます。別のテスト環境で有効化したくない場合は require の場所を制限してください（`spec/spec_helper.rb` 限定 等）。

## 進め方

1. 通常モードで未確定を貯めながら、現状の挙動をテストに固定する（AI が書ける）
2. 定期的にレポートを見て、未確定の仕様を人間が決めていく
3. ほぼ確定したら CI で `RSPEC_UNDEFINED_STRICT=1` を有効にし、新規の未確定混入を防ぐ

最終的に `rspec-undefined` が Gemfile から消えれば、未確定の仕様がない状態です。そこからシステム延命するのか、リプレイスするのか、ハーネスを作っていくのか、改善するのか、それを決めるのは人間の仕事です。

## 貢献について

このリポジトリは公開されていますが、**Pull Request をマージ対象として受け付けるのは、Contributor に登録されたメンバーからのもののみ**です。

### なぜそうしているか

昨今、LLM を使って無関係・低品質な PR を大量に送りつけるケースが増えています。本プロジェクトは少人数でメンテナンスしている OSS であり、レビュー負荷を現実的な範囲に収めるため、以下の運用を取っています。

- **Contributor 登録者以外からの PR は原則クローズします**
- バグ報告・機能要望・議論の Issue は歓迎します
- 協力に興味がある方は、まず GitHub Issue でお声がけください。内容を確認したうえで、適切と判断した場合に Contributor に招待します

### Issue の書き方

- **バグ報告**: 再現手順 / 期待する挙動 / 実際の挙動 / Ruby・RSpec・OS のバージョン
- **機能要望**: 動機 / 想定ユースケース / 代替案（もしあれば）

### AI 利用について

コード生成・執筆に AI を使うこと自体は問題ありません。特に [Claude Code](https://claude.com/claude-code) の利用を推奨しています（本プロジェクトのメンテナも Claude Code を使って開発しています）。

ただし以下は必須です。

- 変更意図を人間が理解しており、PR 説明を自分の言葉で書ける
- `bin/docker-test.sh` が通る
- README に記載の設計思想から逸脱していない

「プロンプトの出力をそのまま投げた」ように見える PR はお断りします。

## 対応 Ruby / RSpec

| | バージョン |
|---|---|
| Ruby | `>= 2.0.0` |
| rspec-core | `>= 3.0, < 4` |

CI（GitHub Actions）では **Ruby 2.2 / 2.7 / 3.1 / 3.3** を Docker コンテナでテストしています。Ruby 2.0 は公式 Docker イメージが現行 Docker で動かない（古いマニフェスト形式）ため、ローカルのみでテスト可能です。

## ローカルでの Docker テスト

`bin/docker-test.sh` で Ruby 2.0, 2.2, 2.7, 3.1, 3.3 すべてでテストを実行できます:

```
bin/docker-test.sh
```

- Ruby 2.2 以降は公式 `ruby:X.X` イメージを使用
- Ruby 2.0 は `docker/ruby-2.0.Dockerfile` からソースビルドした amd64 イメージを使用（初回ビルド約 7 分、2 回目以降はキャッシュ利用）
- Apple Silicon では Ruby 2.0 は amd64 エミュレーションで動作

Ruby 2.0/2.2 では以下のテストが条件付きスキップされます:

- CSV レポーターテスト: `csv` gem (≥ 3.0) が Ruby 2.3+ 必須のため Ruby < 2.3 でスキップ
- YAML レポーターテスト: `YAML.safe_load` が未提供の Ruby 2.0 の Psych でスキップ

## 参考文献

- [ユーザのための要件定義ガイド 第2版 要件定義を成功に導く128の勘どころ（IPA）](https://www.ipa.go.jp/archive/publish/tn20191220.html)
- [非機能要求グレード（IPA）](https://www.ipa.go.jp/archive/digital/iot-en-ci/jyouryuu/index.html)
- [システム再構築を成功に導くユーザガイド（IPA）](https://www.ipa.go.jp/archive/publish/qv6pgp000000117x-att/000057294.pdf)
- [現行踏襲仕様書という考え方（Zenn）](https://zenn.dev/tokium_dev/articles/a8e7af3930a473)

## ライセンス

MIT

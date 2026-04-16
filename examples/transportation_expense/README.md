# 経費精算（交通費）サンプル

`rspec-undefined` の最も基本的な使い方を、最小構成で示すサンプルです。
題材は **交通費の払い戻し額計算** で、マッチャ `be_undefined` を 1 つの spec ファイルから使います。

## 何を見せているか

`TransportationExpense#reimbursement` は「距離 × 単価」をそのまま返すだけの最小実装で、
これを「現行踏襲のテスト」として 1 本ピン留めしています。

そのうえで、仕様判断が **未確定** な以下の 2 つを `be_undefined` で記録しています。

- 消費税の扱い（税込で返すべきか、税抜のままで良いか） → `:tax_handling`
- 小数点以下の端数処理（切り上げ / 切り捨て / 四捨五入） → `:rounding`

`:rounding` は標準カテゴリですが、`:tax_handling` はプロジェクト独自のカテゴリとして `spec/spec_helper.rb` で `register_categories` により登録しています。標準カテゴリでは表現しきれない切り口を追加したいときの典型的な使い方です。

## 実行方法

このディレクトリで以下を実行してください。リポジトリ本体の gem を `path:` で参照しています。

```sh
bundle install
bundle exec rspec
```

3 本中 1 本は通常の green、残り 2 本は `be_undefined` によって「未確定として記録」され、テスト終了時にサマリが表示されます。

### strict モード

`RSPEC_UNDEFINED_STRICT=1` を付けて実行すると、`be_undefined` を呼び出した example はすべて failure 扱いになります（未確定項目が残っていることを CI で検出する用途）。

```sh
RSPEC_UNDEFINED_STRICT=1 bundle exec rspec
```

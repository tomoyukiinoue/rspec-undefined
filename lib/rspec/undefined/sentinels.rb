# frozen_string_literal: true

module RSpec
  module Undefined
    # レポーター共通の Symbol 値文字列化ヘルパ。
    # be_undefined 系マッチャが expected / actual に埋め込むセンチネル Symbol
    # （:__any__, :__nil_or_empty__）を含め、Symbol は一律 to_s で文字列化する。
    # センチネルと通常 Symbol を区別しないのは、旧実装の Hash マッピングが
    # キーと値を to_s 相当で等価に扱っていたため（互換維持）。
    module Sentinels
      module_function

      # Symbol は to_s で String 化する。
      # 非 Symbol は、ブロックが与えられればその結果を、無ければ値をそのまま返す。
      def normalize(value)
        return value.to_s if value.is_a?(Symbol)
        block_given? ? yield(value) : value
      end
    end
  end
end

# frozen_string_literal: true

module RSpec
  module Undefined
    # レポーター共通のセンチネル Symbol 定義と文字列化ヘルパ。
    # be_undefined 系マッチャが expected に埋め込む内部 Symbol（例: :__any__）を
    # 各レポーターで一貫して出力するために集約している。
    module Sentinels
      NAMES = %i[__any__ __nil_or_empty__].freeze

      module_function

      def sentinel?(value)
        value.is_a?(Symbol) && NAMES.include?(value)
      end

      # Symbol なら to_s、それ以外はブロック（無ければ値そのまま）で変換。
      def normalize(value)
        return value.to_s if value.is_a?(Symbol)
        block_given? ? yield(value) : value
      end
    end
  end
end

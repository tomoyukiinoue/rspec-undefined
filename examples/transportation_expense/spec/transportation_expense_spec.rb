require "spec_helper"

RSpec.describe TransportationExpense do
  describe "#reimbursement" do
    it "距離 × 単価 を払い戻す（現行踏襲）" do
      expect(subject.reimbursement(distance_km: 10, unit_price: 30)).to eq(300)
    end

    it "消費税の扱いは未確定（現行は税抜のまま返す）" do
      result = subject.reimbursement(distance_km: 10, unit_price: 30)
      expect(result).to be_undefined(:tax_handling, expected: 300)
    end

    it "小数点以下の端数処理は未確定（現行はそのまま）" do
      result = subject.reimbursement(distance_km: 10.5, unit_price: 30)
      expect(result).to be_undefined(:rounding, expected: 315.0)
    end
  end
end

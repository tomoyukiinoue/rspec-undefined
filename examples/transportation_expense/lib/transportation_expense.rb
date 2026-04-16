# frozen_string_literal: true

class TransportationExpense
  def reimbursement(distance_km:, unit_price:)
    distance_km * unit_price
  end
end

class Order < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :product_name, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price_cents, presence: true, numericality: { greater_than: 0 }

  # Instance methods
  def price_dollars
    price_cents / 100.0
  end

  def total_cents
    quantity * price_cents
  end

  def total_dollars
    total_cents / 100.0
  end

  def to_json_rpc_data
    {
      id: id,
      user_id: user_id,
      user_name: user.name,
      user_email: user.email,
      product_name: product_name,
      quantity: quantity,
      price_cents: price_cents,
      price_dollars: price_dollars,
      total_cents: total_cents,
      total_dollars: total_dollars,
      created_at: created_at.iso8601
    }
  end
end

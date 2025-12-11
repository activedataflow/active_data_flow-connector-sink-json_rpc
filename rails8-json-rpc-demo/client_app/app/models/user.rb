class User < ApplicationRecord
  # Associations
  has_many :orders, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :age, numericality: { greater_than: 0, allow_nil: true }

  # Instance methods
  def to_json_rpc_data
    {
      id: id,
      name: name,
      email: email,
      age: age,
      created_at: created_at.iso8601
    }
  end
end

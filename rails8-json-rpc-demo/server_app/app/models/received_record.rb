class ReceivedRecord < ApplicationRecord
  # Validations
  validates :record_type, presence: true
  validates :source_id, presence: true
  validates :data, presence: true

  # Scopes
  scope :by_type, ->(type) { where(record_type: type) }
  scope :recent, -> { order(received_at: :desc) }
  scope :processed, -> { where.not(processed_at: nil) }
  scope :unprocessed, -> { where(processed_at: nil) }

  # Instance methods
  def processed?
    processed_at.present?
  end

  def mark_as_processed!
    update!(processed_at: Time.current)
  end
end

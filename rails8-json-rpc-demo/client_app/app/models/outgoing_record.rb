class OutgoingRecord < ApplicationRecord
  # Validations
  validates :record_type, presence: true
  validates :data, presence: true
  validates :status, inclusion: { in: %w[pending sent failed] }

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :sent, -> { where(status: 'sent') }
  scope :failed, -> { where(status: 'failed') }
  scope :by_type, ->(type) { where(record_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def mark_as_sent!
    update!(status: 'sent', sent_at: Time.current)
  end

  def mark_as_failed!(error)
    update!(
      status: 'failed',
      error_message: error.to_s,
      retry_count: retry_count + 1
    )
  end

  def retry!
    update!(status: 'pending', error_message: nil)
  end

  def can_retry?
    failed? && retry_count < 3
  end

  def pending?
    status == 'pending'
  end

  def sent?
    status == 'sent'
  end

  def failed?
    status == 'failed'
  end
end

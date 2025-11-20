# frozen_string_literal: true

module ActiveDataFlow
  class DataFlow < ApplicationRecord
    # Model representing a registered data flow
    validates :name, presence: true, uniqueness: true
    validates :source_type, presence: true
    validates :sink_type, presence: true
  end
end

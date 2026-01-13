# frozen_string_literal: true

module ActiveDataFlow
  module Runtime
    module Heartbeat
      class Base
        attr_accessor :name, :source, :sink, :runtime, :message_id_calc

        def initialize(options = {})
          @message_id_calc = options[:message_id_calc] || lambda { |message| message['id'] }
          @transform_collision = options[:transform_collision] || true
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'functional_task_supervisor'

module FunctionalTaskSupervisor
  class Stage
    class << self
      # Store a connector instance at the class level
      attr_accessor :instance
    end

    # Access the class-level instance from instance methods
    def connector
      self.class.instance
    end
  end
end

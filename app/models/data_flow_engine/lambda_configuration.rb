module DataFlowEngine
  class LambdaConfiguration < ApplicationRecord
    # Associations
    belongs_to :data_flow

    # Validations
    validates :function_name, presence: true
    validates :code_language, inclusion: { in: %w[ruby go rust] }
    validates :runtime, presence: true
    validates :handler, presence: true
    validates :memory_size, numericality: { greater_than: 0, less_than_or_equal_to: 10240 }
    validates :timeout, numericality: { greater_than: 0, less_than_or_equal_to: 900 }

    # Callbacks
    before_validation :set_defaults, on: :create

    # Scopes
    scope :by_language, ->(language) { where(code_language: language) }
    scope :deployed, -> { where.not(aws_function_arn: nil) }

    # Instance methods
    def deploy
      service = DataFlowEngine::LambdaService.new(self)
      result = service.deploy
      
      if result[:success]
        update(
          aws_function_arn: result[:function_arn],
          aws_version: result[:version]
        )
      end
      
      result
    end

    def update_code(new_code)
      update(function_code: new_code)
      deploy if deployed?
    end

    def deployed?
      aws_function_arn.present?
    end

    def runtime_for_language
      case code_language
      when 'ruby'
        'ruby3.2'
      when 'go'
        'provided.al2023'
      when 'rust'
        'provided.al2023'
      else
        runtime
      end
    end

    def requires_container?
      %w[go rust].include?(code_language)
    end

    private

    def set_defaults
      self.runtime ||= runtime_for_language
      self.memory_size ||= 512
      self.timeout ||= 30
      self.environment_variables ||= {}
    end
  end
end

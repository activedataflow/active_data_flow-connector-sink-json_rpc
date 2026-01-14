# frozen_string_literal: true

module ActiveDataFlow
  module StorageBackend
    # Loader for ActiveRecord storage backend.
    class ActiveRecordLoader
      class << self
        include ActiveDataFlow::Result

        # Loads ActiveRecord backend.
        #
        # @return [Dry::Monads::Result] Success(:active_record)
        def load!
          yield validate_dependencies
          Success(:active_record)
        end

        # Validates ActiveRecord dependencies.
        #
        # @return [Dry::Monads::Result] Success(:valid)
        def validate_dependencies
          # ActiveRecord is part of Rails, so no additional validation needed
          Success(:valid)
        end

        # Configures autoload paths for ActiveRecord models.
        #
        # @param engine [Rails::Engine] The engine to configure
        def setup_autoload_paths(engine)
          path = engine.root.join("app/models/active_data_flow/active_record")
          engine.config.autoload_paths += [path] unless engine.config.autoload_paths.include?(path)
          engine.config.eager_load_paths += [path] unless engine.config.eager_load_paths.include?(path)
        end

        # Logs backend configuration.
        #
        # @param logger [Logger]
        def log_configuration(logger)
          logger.info "[ActiveDataFlow] Storage backend: active_record"
        end
      end
    end
  end
end

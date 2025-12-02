# Implementation Plan

- [x] 1. Enhance Configuration module with storage backend options
  - Add `storage_backend` attribute (default: `:active_record`)
  - Add `redis_config` attribute (default: empty hash)
  - Implement validation method `validate_storage_backend!`
  - Add helper methods: `active_record?`, `redcord?`, `redcord_redis?`, `redcord_redis_emulator?`
  - _Requirements: 1.1, 1.2, 1.4, 1.5_

- [x] 1.1 Write property test for configuration validation
  - **Property 1: Configuration validation**
  - **Validates: Requirements 1.1, 1.4, 1.5, 9.1**

- [x] 2. Create Storage Backend Loader
  - Create `lib/active_data_flow/storage_backend_loader.rb`
  - Implement `self.load!` method to read configuration and load appropriate backend
  - Implement `self.setup_autoload_paths(engine)` to configure Rails autoload paths
  - Implement `self.validate_dependencies!` to check required gems are installed
  - Add error classes: `ConfigurationError`, `ConnectionError`, `DependencyError`
  - _Requirements: 1.3, 5.1, 5.4, 9.1, 9.2_

- [x] 2.1 Write property test for backend-specific model loading
  - **Property 2: Backend-specific model loading**
  - **Validates: Requirements 1.3, 5.2, 5.3**

- [x] 3. Refactor existing ActiveRecord models
  - Create directory `app/models/active_data_flow/active_record/`
  - Move `app/models/active_data_flow/data_flow.rb` to `app/models/active_data_flow/active_record/data_flow.rb`
  - Move `app/models/active_data_flow/data_flow_run.rb` to `app/models/active_data_flow/active_record/data_flow_run.rb`
  - Update namespace to `ActiveDataFlow::ActiveRecord::DataFlow` and `ActiveDataFlow::ActiveRecord::DataFlowRun`
  - Add module aliasing to maintain backward compatibility: `ActiveDataFlow::DataFlow = ActiveDataFlow::ActiveRecord::DataFlow`
  - _Requirements: 2.1, 2.2, 2.5_

- [x] 3.1 Write unit tests for ActiveRecord models
  - Test DataFlow model validations, associations, and methods
  - Test DataFlowRun model validations, associations, and methods
  - Test backward compatibility with existing code
  - _Requirements: 2.1, 2.2, 2.4, 2.5_

- [x] 4. Implement Redcord models
  - Create directory `app/models/active_data_flow/redcord/`
  - Create `app/models/active_data_flow/redcord/data_flow.rb` with Redcord schema
  - Create `app/models/active_data_flow/redcord/data_flow_run.rb` with Redcord schema
  - Implement all public methods to match ActiveRecord interface
  - Implement associations using Redcord DSL
  - Implement scopes using Redcord query methods
  - Handle JSON serialization for complex attributes (source, sink, runtime)
  - Use Unix timestamps for datetime fields
  - _Requirements: 3.1, 3.2, 3.4, 3a.1, 3a.2, 4.1, 4.2_

- [x] 4.1 Write property test for model interface consistency
  - **Property 3: Model interface consistency**
  - **Validates: Requirements 4.1, 4.2, 3a.5**

- [x] 4.2 Write property test for behavioral consistency
  - **Property 4: Behavioral consistency across backends**
  - **Validates: Requirements 4.3, 4.4, 4.5, 2.4, 3.4**

- [x] 4.3 Write unit tests for Redcord models
  - Test DataFlow model validations, associations, and methods
  - Test DataFlowRun model validations, associations, and methods
  - Test JSON serialization/deserialization
  - Test Unix timestamp handling
  - _Requirements: 3.1, 3.2, 3.4, 3a.1_

- [x] 5. Implement Redis connection management
  - Add `self.initialize_redis_connection` method to StorageBackendLoader
  - Support Redis URL configuration
  - Support Redis host/port/db configuration
  - Validate Redis connectivity with ping
  - Raise ConnectionError with clear message on failure
  - _Requirements: 3.5, 7.1, 7.2, 7.4, 7.5, 9.3_

- [x] 5.1 Write property test for Redis configuration flexibility
  - **Property 5: Redis configuration flexibility**
  - **Validates: Requirements 7.2, 7.5**

- [x] 5.2 Write unit tests for Redis connection management
  - Test connection with URL configuration
  - Test connection with host/port/db configuration
  - Test connection failure handling
  - Test error messages
  - _Requirements: 7.1, 7.2, 7.4, 7.5, 9.3_

- [x] 6. Implement Redis Emulator support
  - Add `self.initialize_redis_emulator` method to StorageBackendLoader
  - Configure Redcord to use Redis::Emulator
  - Use Rails.cache as backing store
  - No connectivity validation needed (uses Rails.cache)
  - _Requirements: 3a.1, 3a.2, 3a.3, 7.3_

- [x] 6.1 Write unit tests for Redis Emulator initialization
  - Test Redis::Emulator configuration
  - Test Rails.cache backing store
  - Test Redcord configuration
  - _Requirements: 3a.1, 3a.2, 3a.3, 7.3_

- [x] 7. Integrate Storage Backend Loader into Engine
  - Update `lib/active_data_flow/engine.rb`
  - Add initializer `active_data_flow.load_storage_backend` before `:load_config_initializers`
  - Call `ActiveDataFlow::StorageBackendLoader.load!` in initializer
  - Add logging for configured backend at startup
  - _Requirements: 5.1, 5.5, 9.5_

- [x] 7.1 Write integration tests for engine initialization
  - Test engine loads with ActiveRecord backend
  - Test engine loads with Redcord Redis backend
  - Test engine loads with Redcord Redis Emulator backend
  - Test models are available after initialization
  - Test logging output
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 9.5_

- [x] 8. Create configuration file generator
  - Create `lib/generators/active_data_flow/install_generator.rb`
  - Generate `config/initializers/active_data_flow.rb` with template
  - Include commented examples for all three backends
  - Include documentation about required gems
  - Include Redis configuration examples
  - Check for existing file and prompt before overwriting
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 8.1 Write unit tests for install generator
  - Test generator creates configuration file
  - Test generated file contains all backend examples
  - Test generated file contains gem documentation
  - Test generator doesn't overwrite existing file without confirmation
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 9. Update central glossary
  - Ensure `.kiro/glossary.md` has all storage backend terms
  - Add definitions for new error classes
  - _Requirements: All_

- [x] 10. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. Configure rails8-redcord example application
  - Generate configuration file: `rails generate active_data_flow:install`
  - Set `storage_backend` to `:redcord_redis_emulator`
  - Verify redis-emulator and redcord gems are in Gemfile
  - Test DataFlow creation and execution
  - Test heartbeat endpoint
  - _Requirements: 3a.1, 3a.2, 3a.3, 10.6_

- [x] 11.1 Write system tests for rails8-redcord example
  - Test full DataFlow lifecycle
  - Test DataFlowRun creation and execution
  - Test UI displays DataFlows correctly
  - Test heartbeat endpoint triggers execution
  - _Requirements: 10.6_

- [x] 12. Update README documentation
  - Add section on storage backend configuration
  - Document all three backend options with examples
  - Document required gems for each backend
  - Document trade-offs between backends (performance, features, complexity)
  - Add migration guide for existing installations
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 13. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

add .
# Implementation Plan

- [ ] 1. Implement core message types
  - [x] 1.1 Implement Message::Untyped class with data accessors
    - Create `lib/message/untyped.rb` with initialization and data access methods
    - _Requirements: 2.2, 2.3, 2.5_
  - [ ] 1.2 Implement Message::Typed class with schema validation
    - Create `lib/message/typed.rb` with schema validation logic
    - _Requirements: 2.1, 2.3, 2.5_

- [ ] 2. Implement connector base classes
  - [ ] 2.1 Implement Connector::Source base class
    - Create `lib/connector/source/source.rb` with `each` method and configuration handling
    - _Requirements: 1.1, 1.3, 1.5_
  - [ ] 2.2 Implement Connector::Sink base class
    - Create `lib/connector/sink/sink.rb` with `write` method and configuration handling
    - _Requirements: 1.2, 1.4, 1.5_

- [ ] 3. Implement runtime base classes
  - [ ] 3.1 Implement Runtime base class
    - Create `lib/runtime/runtime.rb` with configuration and execution strategy interface
    - _Requirements: 4.1, 4.4_
  - [ ] 3.2 Implement Runtime::Runner base class
    - Create `lib/runtime/runner.rb` with DataFlow execution interface
    - _Requirements: 4.2, 4.3, 4.5_

- [ ] 4. Implement DataFlow orchestration base class
  - [ ] 4.1 Create DataFlow base class with source/sink configuration
    - Create `lib/data_flow.rb` with configuration methods for sources and sinks
    - _Requirements: 7.1, 7.2_
  - [ ] 4.2 Implement DataFlow run method
    - Add run method that orchestrates read-transform-write loops
    - _Requirements: 7.3, 7.4, 7.5_

- [ ] 5. Create main gem entry point
  - [ ] 5.1 Create main ActiveDataflow module file
    - Create `lib/active_data_flow.rb` that requires all core components
    - _Requirements: 8.1_
  - [ ] 5.2 Add error handling classes
    - Create `lib/errors.rb` with custom exception classes
    - _Requirements: 3.5, 5.5_

- [ ] 6. Implement ActiveRecord source connector
  - [ ] 6.1 Create ActiveRecord source implementation
    - Create subgem structure for `connector/source/active_record`
    - Implement `each` method that yields records from ActiveRecord model
    - _Requirements: 3.1, 3.3, 3.5_
  - [ ] 6.2 Write unit tests for ActiveRecord source
    - Create RSpec tests for ActiveRecord source connector
    - _Requirements: 3.1, 3.3_

- [ ] 7. Implement ActiveRecord sink connector
  - [ ] 7.1 Create ActiveRecord sink implementation
    - Create subgem structure for `connector/sink/active_record`
    - Implement `write` method that persists records to ActiveRecord model
    - _Requirements: 3.2, 3.4, 3.5_
  - [ ] 7.2 Write unit tests for ActiveRecord sink
    - Create RSpec tests for ActiveRecord sink connector
    - _Requirements: 3.2, 3.4_

- [ ] 8. Implement Heartbeat runtime
  - [ ] 8.1 Create Heartbeat runtime implementation
    - Create subgem structure for `runtime/heartbeat`
    - Implement periodic execution logic
    - _Requirements: 5.1, 5.3, 5.4, 5.5_
  - [ ] 8.2 Create Heartbeat runner implementation
    - Implement runner that executes DataFlows on heartbeat trigger
    - _Requirements: 5.2, 5.5_
  - [ ] 8.3 Write unit tests for Heartbeat runtime
    - Create RSpec tests for Heartbeat runtime and runner
    - _Requirements: 5.1, 5.2_

- [ ] 9. Implement Rails engine integration
  - [ ] 9.1 Create Rails engine structure
    - Create `lib/active_data_flow/engine.rb` with Rails::Engine configuration
    - _Requirements: 6.1_
  - [ ] 9.2 Create DataFlow controller
    - Create controller for DataFlow CRUD operations
    - _Requirements: 6.2_
  - [ ] 9.3 Create DataFlow model
    - Create ActiveRecord model for DataFlow persistence
    - _Requirements: 6.5_
  - [ ] 9.4 Create routes for heartbeat endpoints
    - Add routes configuration for heartbeat triggers
    - _Requirements: 6.4_
  - [ ] 9.5 Create views for DataFlow monitoring
    - Create basic views for DataFlow management interface
    - _Requirements: 6.3_
  - [ ] 9.6 Write integration tests for Rails engine
    - Create RSpec tests for controller and model interactions
    - _Requirements: 6.1, 6.2, 6.3_

- [ ] 10. Create gemspec and configuration files
  - [ ] 10.1 Create main gemspec file
    - Create `active_data_flow.gemspec` with dependencies and metadata
    - _Requirements: 8.1_
  - [ ] 10.2 Create Gemfile for development
    - Create `Gemfile` with development dependencies
    - _Requirements: 8.1_
  - [ ] 10.3 Create subgem gemspecs
    - Create gemspec files for each subgem (ActiveRecord connectors, Heartbeat runtime)
    - _Requirements: 8.2, 8.4_

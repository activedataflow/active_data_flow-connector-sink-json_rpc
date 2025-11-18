# Install Generator Requirements

## Introduction

The Install Generator provides a Rails generator that automates the installation of the Heartbeat Runtime gem, including database migrations and configuration file creation.

## Glossary

- **Rails Generator**: A Rails command-line tool that generates boilerplate code and files
- **Migration**: A database schema change file that Rails uses to modify the database structure
- **Initializer**: A Ruby file in config/initializers that runs when the Rails application starts
- **Host Application**: The Rails application that includes the Heartbeat Runtime gem

## Requirements

### Requirement 1: Generator Structure

**User Story:** As a Rails developer, I want an install generator, so that I can set up the gem with a single command

#### Acceptance Criteria

1. THE install generator SHALL be invoked with rails generate active_data_flow:runtime:heartbeat:install
2. THE install generator SHALL inherit from Rails::Generators::Base
3. THE install generator SHALL be namespaced under ActiveDataFlow::Runtime::Heartbeat::Generators
4. THE install generator SHALL define a source_root pointing to the templates directory
5. THE install generator SHALL execute all installation steps in the correct order

### Requirement 2: Migration Copying

**User Story:** As a Rails developer, I want database migrations copied to my application, so that I can create the required tables

#### Acceptance Criteria

1. THE install generator SHALL copy the create_data_flows migration to db/migrate
2. THE install generator SHALL copy the create_data_flow_runs migration to db/migrate
3. THE install generator SHALL timestamp the migrations with the current time
4. THE install generator SHALL ensure migrations are copied in dependency order
5. THE install generator SHALL skip copying if migrations already exist

### Requirement 3: Initializer Creation

**User Story:** As a Rails developer, I want an initializer file created, so that I can configure the gem

#### Acceptance Criteria

1. THE install generator SHALL create a file at config/initializers/active_data_flow.rb
2. THE initializer SHALL include a configuration block with examples
3. THE initializer SHALL include comments explaining each configuration option
4. THE initializer SHALL set authentication_enabled to false by default
5. THE initializer SHALL include instructions for setting environment variables

### Requirement 4: Configuration Examples

**User Story:** As a Rails developer, I want configuration examples in the initializer, so that I know how to configure the gem

#### Acceptance Criteria

1. THE initializer SHALL include an example of enabling authentication
2. THE initializer SHALL include an example of setting the authentication token from ENV
3. THE initializer SHALL include an example of enabling IP whitelisting
4. THE initializer SHALL include an example of adding whitelisted IPs
5. THE initializer SHALL include comments explaining security best practices

### Requirement 5: Output Messages

**User Story:** As a Rails developer, I want clear output messages, so that I know what the generator did and what to do next

#### Acceptance Criteria

1. THE install generator SHALL output a message when copying migrations
2. THE install generator SHALL output a message when creating the initializer
3. THE install generator SHALL output instructions to run rails db:migrate
4. THE install generator SHALL output instructions to configure the initializer
5. THE install generator SHALL use colored output for better readability

### Requirement 6: Idempotency

**User Story:** As a Rails developer, I want the generator to be idempotent, so that I can run it multiple times safely

#### Acceptance Criteria

1. THE install generator SHALL check if migrations already exist before copying
2. THE install generator SHALL check if the initializer already exists before creating
3. WHEN files already exist, THE install generator SHALL output a skip message
4. THE install generator SHALL not overwrite existing files without confirmation
5. THE install generator SHALL provide a --force option to overwrite existing files

### Requirement 7: Migration Templates

**User Story:** As a Rails developer, I want migration templates included, so that the correct database schema is created

#### Acceptance Criteria

1. THE install generator SHALL include a template for create_data_flows migration
2. THE create_data_flows migration SHALL create a table with all required columns
3. THE install generator SHALL include a template for create_data_flow_runs migration
4. THE create_data_flow_runs migration SHALL create a table with all required columns and foreign keys
5. THE migrations SHALL include appropriate indexes for performance

### Requirement 8: Initializer Template

**User Story:** As a Rails developer, I want an initializer template included, so that I have a starting point for configuration

#### Acceptance Criteria

1. THE install generator SHALL include a template for the initializer file
2. THE initializer template SHALL use ERB for dynamic content
3. THE initializer template SHALL include the ActiveDataFlow::Runtime::Heartbeat.configure block
4. THE initializer template SHALL include all available configuration options
5. THE initializer template SHALL have sensible defaults that work out of the box

### Requirement 9: Documentation

**User Story:** As a Rails developer, I want generator documentation, so that I know how to use it

#### Acceptance Criteria

1. THE install generator SHALL include a desc block describing its purpose
2. THE install generator SHALL appear in rails generate --help output
3. THE install generator SHALL include usage examples in the description
4. THE install generator SHALL document any available options
5. THE install generator SHALL include a link to full documentation

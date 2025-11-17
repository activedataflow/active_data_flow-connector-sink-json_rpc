# Requirements Document

## Introduction

The Install Generator feature provides a Rails generator that automates the installation of the Rails Heartbeat App gem, including database migrations and configuration initializer creation.

## Glossary

- **Install Generator**: A Rails generator class that automates gem installation tasks
- **Migration Template**: A template file used to generate database migration files
- **Initializer Template**: A template file used to generate Rails configuration files
- **Migration Number**: A timestamp-based number used to order database migrations
- **Source Root**: The directory containing generator template files

## Requirements

### Requirement 1

**User Story:** As a Rails developer, I want to run a generator command, so that I can install the gem with a single command

#### Acceptance Criteria

1. THE Install Generator SHALL inherit from Rails::Generators::Base
2. THE Install Generator SHALL include Rails::Generators::Migration module
3. THE Install Generator SHALL be invokable via `rails generate active_data_flow:rails_heartbeat_app:install`
4. THE Install Generator SHALL set the source root to the templates directory
5. THE Install Generator SHALL execute all installation steps when invoked

### Requirement 2

**User Story:** As a Rails developer, I want database migrations created, so that the required tables are added to my database schema

#### Acceptance Criteria

1. THE Install Generator SHALL copy a migration template for creating the data_flows table
2. THE Install Generator SHALL copy a migration template for creating the data_flow_runs table
3. THE Install Generator SHALL place migrations in the db/migrate directory
4. THE Install Generator SHALL generate unique migration numbers for each migration
5. THE Install Generator SHALL use the `migration_template` method to create timestamped migrations

### Requirement 3

**User Story:** As a Rails developer, I want migration numbers to be sequential, so that migrations run in the correct order

#### Acceptance Criteria

1. THE Install Generator SHALL provide a `next_migration_number` class method
2. THE Install Generator SHALL calculate the next migration number based on existing migrations
3. THE Install Generator SHALL use ActiveRecord::Migration.next_migration_number for formatting
4. THE Install Generator SHALL increment the current migration number by 1
5. THE Install Generator SHALL ensure each migration has a unique number

### Requirement 4

**User Story:** As a Rails developer, I want a configuration initializer created, so that I can customize gem settings

#### Acceptance Criteria

1. THE Install Generator SHALL copy an initializer template
2. THE Install Generator SHALL place the initializer in config/initializers directory
3. THE Install Generator SHALL name the initializer file "active_data_flow_rails_heartbeat_app.rb"
4. THE Install Generator SHALL use the `template` method to process the initializer template
5. THE Install Generator SHALL create the initializer with default configuration settings

### Requirement 5

**User Story:** As a Rails developer, I want template files organized, so that the generator can locate and use them

#### Acceptance Criteria

1. THE Install Generator SHALL define templates in a "templates" subdirectory
2. THE Install Generator SHALL locate the templates directory relative to the generator file
3. THE Install Generator SHALL use File.expand_path to resolve the templates path
4. THE Install Generator SHALL access template files by name during generation
5. THE Install Generator SHALL support multiple template files in the templates directory

# Flow Generator Requirements

## Introduction

The Flow Generator provides a Rails generator that creates DataFlow subclass templates, making it easy for developers to scaffold new flows.

## Glossary

- **Flow Generator**: A Rails generator that creates DataFlow subclass files
- **DataFlow Subclass**: A Ruby class that inherits from a base DataFlow class and implements the run method
- **Template**: An ERB file used by the generator to create the flow class file
- **Namespace**: The Ruby module hierarchy where the generated class is placed

## Requirements

### Requirement 1: Generator Structure

**User Story:** As a developer, I want a flow generator, so that I can quickly create new DataFlow subclasses

#### Acceptance Criteria

1. THE flow generator SHALL be invoked with rails generate active_data_flow:runtime:heartbeat:flow NAME
2. THE flow generator SHALL inherit from Rails::Generators::NamedBase
3. THE flow generator SHALL be namespaced under ActiveDataFlow::Runtime::Heartbeat::Generators
4. THE flow generator SHALL define a source_root pointing to the templates directory
5. THE flow generator SHALL accept a NAME argument for the flow class name

### Requirement 2: File Generation

**User Story:** As a developer, I want a flow class file created, so that I have a starting point for implementation

#### Acceptance Criteria

1. THE flow generator SHALL create a file in app/flows directory
2. THE generated file SHALL be named after the flow name in snake_case
3. THE generated file SHALL have a .rb extension
4. THE flow generator SHALL create the app/flows directory if it doesn't exist
5. THE flow generator SHALL not overwrite existing files without confirmation

### Requirement 3: Class Template

**User Story:** As a developer, I want a properly structured class template, so that I know how to implement the flow

#### Acceptance Criteria

1. THE generated class SHALL inherit from a base flow class
2. THE generated class SHALL be properly namespaced
3. THE generated class SHALL include a run method stub
4. THE generated class SHALL include comments explaining how to implement the flow
5. THE generated class SHALL follow Ruby style conventions

### Requirement 4: Run Method Stub

**User Story:** As a developer, I want a run method stub, so that I know where to implement flow logic

#### Acceptance Criteria

1. THE generated class SHALL define a run method
2. THE run method SHALL include a comment explaining its purpose
3. THE run method SHALL include a TODO comment for implementation
4. THE run method SHALL have an empty body ready for implementation
5. THE run method SHALL be public

### Requirement 5: Documentation Comments

**User Story:** As a developer, I want documentation comments in the generated file, so that I understand how to use it

#### Acceptance Criteria

1. THE generated file SHALL include a class-level comment describing the flow
2. THE generated file SHALL include comments explaining how to register the flow
3. THE generated file SHALL include comments explaining how to configure the flow
4. THE generated file SHALL include an example of setting run_interval
5. THE generated file SHALL include a link to full documentation

### Requirement 6: Output Messages

**User Story:** As a developer, I want clear output messages, so that I know what the generator created

#### Acceptance Criteria

1. THE flow generator SHALL output a message when creating the flow file
2. THE flow generator SHALL output instructions for registering the flow in the database
3. THE flow generator SHALL output an example DataFlow.create command
4. THE flow generator SHALL use colored output for better readability
5. THE flow generator SHALL include the full path to the generated file

### Requirement 7: Naming Conventions

**User Story:** As a developer, I want proper naming conventions, so that generated files follow Rails standards

#### Acceptance Criteria

1. THE flow generator SHALL convert the NAME argument to PascalCase for the class name
2. THE flow generator SHALL convert the NAME argument to snake_case for the file name
3. THE flow generator SHALL pluralize or singularize names appropriately
4. THE flow generator SHALL handle multi-word names correctly
5. THE flow generator SHALL validate that the NAME argument is a valid Ruby identifier

### Requirement 8: Template File

**User Story:** As a gem maintainer, I want a template file for the generator, so that the generated code is consistent

#### Acceptance Criteria

1. THE flow generator SHALL use an ERB template file
2. THE template file SHALL be located in lib/generators/templates
3. THE template file SHALL use ERB tags for dynamic content
4. THE template file SHALL include the class name from the generator
5. THE template file SHALL be maintainable and well-formatted

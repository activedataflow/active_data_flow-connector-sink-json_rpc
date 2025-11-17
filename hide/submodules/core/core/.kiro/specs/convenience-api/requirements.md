# Convenience API - Requirements Document

## Introduction

The Convenience API provides module-level factory methods that simplify the creation of sources and sinks from the registry. This enables developers to write more concise and readable pipeline code.

## Glossary

- **System**: The ActiveDataFlow Core gem
- **Source**: A component that produces data messages for processing
- **Sink**: A component that consumes and writes data messages to a destination
- **Registry**: A central repository that manages registered sources, sinks, and runtime implementations
- **Developer**: A user who creates pipelines using the System

## Requirements

### Requirement 1: Convenience Methods

**User Story:** As a developer, I want convenient factory methods to create sources and sinks from the registry, so that I can write concise pipeline code.

#### Acceptance Criteria

1.1 THE System SHALL provide a module-level source method that accepts a type symbol and configuration hash

1.2 WHEN the source method is called, THE System SHALL look up the source class in the Registry and return a new instance

1.3 THE System SHALL provide a module-level sink method that accepts a type symbol and configuration hash

1.4 WHEN the sink method is called, THE System SHALL look up the sink class in the Registry and return a new instance

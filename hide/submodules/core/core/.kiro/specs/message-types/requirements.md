# Message Types - Requirements Document

## Introduction

The Message Types component provides support for multiple message formats including unconstrained data, CloudEvents standard messages, and CloudEvents with Linked Data extensions. This enables integration with various messaging standards and flexible data handling.

## Glossary

- **System**: The ActiveDataFlow Core gem
- **Message**: A typed data container that flows through the system
- **CloudEvent**: A standardized message format following the CloudEvents specification
- **Developer**: A user who works with messages in the System
- **Linked Data**: A method of publishing structured data using JSON-LD context

## Requirements

### Requirement 1: Message Type Support

**User Story:** As a developer, I want to work with multiple message formats including unconstrained data, CloudEvents, and CloudEvents with Linked Data, so that I can integrate with various messaging standards.

#### Acceptance Criteria

1.1 THE System SHALL provide an Unconstrained message type that accepts any Ruby object as data

1.2 WHEN an Unconstrained message is converted to a hash, THE System SHALL return the data if it is a hash, or wrap non-hash data in a value key

1.3 THE System SHALL provide a CloudEvent message type that enforces required attributes: id, source, specversion, and type

1.4 WHEN a CloudEvent is created without a required attribute, THE System SHALL raise a ConfigurationError identifying the missing attribute

1.5 THE System SHALL support optional CloudEvent attributes including datacontenttype, dataschema, subject, time, data, and data_base64

1.6 THE System SHALL provide a CloudEventLd message type that extends CloudEvent with Linked Data support

1.7 WHEN a CloudEventLd is created without a @context attribute, THE System SHALL raise a ConfigurationError

1.8 THE System SHALL provide hash-like access to CloudEvent attributes using bracket notation

1.9 THE System SHALL provide a to_h method that returns all CloudEvent attributes as a hash

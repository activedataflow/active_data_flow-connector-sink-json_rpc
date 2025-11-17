# ActiveRecord Sink Connector Spec

This directory contains the specification for the ActiveRecord sink connector implementation.

## Current Implementation

The sink connector is located at `lib/active_data_flow/sink/active_record.rb` and provides functionality to write records to ActiveRecord models.

## Key Features

- Single record writes with create!
- Batch writes with insert_all
- Upsert support with upsert_all
- Transaction support
- Buffering for batch operations
- Skip validations option
- Error handling

## Future Specs

Create requirement, design, and task documents here for any enhancements or modifications to the sink connector.

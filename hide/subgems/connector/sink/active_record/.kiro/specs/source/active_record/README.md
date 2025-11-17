# ActiveRecord Source Connector Spec

This directory contains the specification for the ActiveRecord source connector implementation.

## Current Implementation

The source connector is located at `lib/active_data_flow/source/active_record.rb` and provides functionality to read records from ActiveRecord models.

## Key Features

- Model-based record iteration
- Query building with where, order, limit, select clauses
- Batch processing with find_each
- Eager loading with includes
- Readonly mode support

## Future Specs

Create requirement, design, and task documents here for any enhancements or modifications to the source connector.

Feature: JSON-RPC Sink Connector
  As a developer using ActiveDataFlow
  I want to send data via JSON-RPC
  So that I can integrate with remote systems as data sinks

  Scenario: Write a single record
    Given a JSON-RPC sink connector
    When I write a single record
    Then the record should be sent successfully

  Scenario: Write multiple records in a batch
    Given a JSON-RPC sink connector
    When I write multiple records in a batch
    Then all records should be sent successfully

  Scenario: Buffer records and flush
    Given a JSON-RPC sink connector with batch size 5
    When I buffer 3 records
    Then the buffer should contain 3 records
    When I flush the buffer
    Then the buffer should be empty

  Scenario: Automatic flush on batch size
    Given a JSON-RPC sink connector with batch size 3
    When I buffer 3 records
    Then the buffer should be automatically flushed

  Scenario: Test connection
    Given a JSON-RPC sink connector
    When I test the connection
    Then the connection test should complete

  Scenario: Check server health
    Given a JSON-RPC sink connector
    When I check the server health
    Then I should receive a health status

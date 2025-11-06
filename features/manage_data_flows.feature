Feature: Manage DataFlows
  As a developer
  I want to manage data flow configurations
  So that I can deploy and sync AWS resources

  Background:
    Given the ActiveDataFlow engine is mounted at "/dataflow"

  Scenario: List all data flows
    Given the following data flows exist:
      | name              | description                  | status |
      | user_registration | Handles user registration    | active |
      | order_processing  | Processes customer orders    | draft  |
    When I send a GET request to "/dataflow"
    Then the response status should be 200
    And the JSON response should contain 2 data flows

  Scenario: Create a new data flow
    When I send a POST request to "/dataflow" with:
      """
      {
        "data_flow": {
          "name": "payment_processing",
          "description": "Handles payment transactions",
          "status": "draft"
        }
      }
      """
    Then the response status should be 201
    And the JSON response should have "name" with value "payment_processing"

  Scenario: Push data flow to AWS
    Given a data flow named "test_flow" exists with Lambda configuration
    When I send a POST request to "/dataflow/test_flow/push"
    Then the response status should be 200
    And the data flow "test_flow" should have sync status "synced"

  Scenario: Pull data flow from AWS
    Given a data flow named "test_flow" exists with deployed Lambda
    When I send a POST request to "/dataflow/test_flow/pull"
    Then the response status should be 200
    And the data flow "test_flow" should be updated with AWS configuration

  Scenario: Check data flow sync status
    Given a data flow named "test_flow" exists
    When I send a GET request to "/dataflow/test_flow/status"
    Then the response status should be 200
    And the JSON response should include sync status information

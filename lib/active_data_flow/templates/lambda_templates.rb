module ActiveDataFlow
  module Templates
    module LambdaTemplates
      # Ruby Lambda template
      RUBY_TEMPLATE = <<~RUBY
        require 'json'

        def handler(event:, context:)
          # Your Lambda function logic here
          puts "Event: \#{event.inspect}"
          
          {
            statusCode: 200,
            body: JSON.generate({
              message: 'Success',
              event: event,
              context: {
                request_id: context.request_id,
                function_name: context.function_name
              }
            })
          }
        rescue StandardError => e
          {
            statusCode: 500,
            body: JSON.generate({
              error: e.message,
              backtrace: e.backtrace.first(5)
            })
          }
        end
      RUBY

      # Go Lambda template
      GO_TEMPLATE = <<~GO
        package main

        import (
          "context"
          "encoding/json"
          "fmt"
          "github.com/aws/aws-lambda-go/lambda"
          "github.com/aws/aws-lambda-go/events"
        )

        type Response struct {
          StatusCode int               `json:"statusCode"`
          Headers    map[string]string `json:"headers"`
          Body       string            `json:"body"`
        }

        type ResponseBody struct {
          Message string      `json:"message"`
          Event   interface{} `json:"event"`
        }

        func HandleRequest(ctx context.Context, event events.APIGatewayProxyRequest) (Response, error) {
          // Your Lambda function logic here
          fmt.Printf("Event: %+v\\n", event)

          responseBody := ResponseBody{
            Message: "Success",
            Event:   event,
          }

          body, err := json.Marshal(responseBody)
          if err != nil {
            return Response{
              StatusCode: 500,
              Body:       fmt.Sprintf(`{"error": "%s"}`, err.Error()),
            }, nil
          }

          return Response{
            StatusCode: 200,
            Headers: map[string]string{
              "Content-Type": "application/json",
            },
            Body: string(body),
          }, nil
        }

        func main() {
          lambda.Start(HandleRequest)
        }
      GO

      # Rust Lambda template
      RUST_TEMPLATE = <<~RUST
        use lambda_runtime::{service_fn, LambdaEvent, Error};
        use serde::{Deserialize, Serialize};
        use serde_json::{json, Value};

        #[derive(Deserialize)]
        struct Request {
            #[serde(flatten)]
            event: Value,
        }

        #[derive(Serialize)]
        struct Response {
            #[serde(rename = "statusCode")]
            status_code: u16,
            body: String,
        }

        async fn function_handler(event: LambdaEvent<Request>) -> Result<Response, Error> {
            // Your Lambda function logic here
            println!("Event: {:?}", event.payload.event);

            let response_body = json!({
                "message": "Success",
                "event": event.payload.event
            });

            Ok(Response {
                status_code: 200,
                body: serde_json::to_string(&response_body)?,
            })
        }

        #[tokio::main]
        async fn main() -> Result<(), Error> {
            let func = service_fn(function_handler);
            lambda_runtime::run(func).await?;
            Ok(())
        }
      RUST

      # Kafka consumer template (Ruby)
      RUBY_KAFKA_CONSUMER_TEMPLATE = <<~RUBY
        require 'json'
        require 'kafka'

        def handler(event:, context:)
          # Kafka configuration
          kafka = Kafka.new(
            seed_brokers: ENV['KAFKA_BROKERS'].split(','),
            client_id: 'activedataflow-consumer'
          )

          consumer = kafka.consumer(group_id: 'dataflow-group')
          consumer.subscribe('your-topic')

          # Process Kafka messages
          consumer.each_message do |message|
            puts "Received message: \#{message.value}"
            
            # Your processing logic here
            process_message(message)
          end

          {
            statusCode: 200,
            body: JSON.generate({ message: 'Kafka consumer processed' })
          }
        end

        def process_message(message)
          # Implement your message processing logic
          data = JSON.parse(message.value)
          puts "Processing: \#{data}"
        end
      RUBY

      # API Gateway integration template (Ruby)
      RUBY_API_GATEWAY_TEMPLATE = <<~RUBY
        require 'json'

        def handler(event:, context:)
          # Parse API Gateway event
          http_method = event['requestContext']['http']['method']
          path = event['requestContext']['http']['path']
          body = event['body'] ? JSON.parse(event['body']) : {}

          # Route handling
          response = case http_method
          when 'GET'
            handle_get(path, event['queryStringParameters'])
          when 'POST'
            handle_post(path, body)
          when 'PUT'
            handle_put(path, body)
          when 'DELETE'
            handle_delete(path)
          else
            { statusCode: 405, body: JSON.generate({ error: 'Method not allowed' }) }
          end

          response
        end

        def handle_get(path, params)
          {
            statusCode: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: JSON.generate({ message: 'GET request', path: path, params: params })
          }
        end

        def handle_post(path, body)
          {
            statusCode: 201,
            headers: { 'Content-Type' => 'application/json' },
            body: JSON.generate({ message: 'POST request', path: path, data: body })
          }
        end

        def handle_put(path, body)
          {
            statusCode: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: JSON.generate({ message: 'PUT request', path: path, data: body })
          }
        end

        def handle_delete(path)
          {
            statusCode: 204,
            headers: { 'Content-Type' => 'application/json' },
            body: ''
          }
        end
      RUBY

      # Get template by language
      def self.get_template(language, type = :basic)
        case language.to_s.downcase
        when 'ruby'
          case type
          when :kafka
            RUBY_KAFKA_CONSUMER_TEMPLATE
          when :api_gateway
            RUBY_API_GATEWAY_TEMPLATE
          else
            RUBY_TEMPLATE
          end
        when 'go'
          GO_TEMPLATE
        when 'rust'
          RUST_TEMPLATE
        else
          raise "Unsupported language: #{language}"
        end
      end
    end
  end
end

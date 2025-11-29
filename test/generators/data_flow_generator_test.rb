# frozen_string_literal: true

require 'test_helper'
require 'rails/generators/test_case'
require 'generators/active_data_flow/data_flow_generator'

module ActiveDataFlow
  module Generators
    class DataFlowGeneratorTest < Rails::Generators::TestCase
      tests ActiveDataFlow::Generators::DataFlowGenerator
      destination File.expand_path("../../tmp", __dir__)
      setup :prepare_destination

      test "generator creates data flow file with default options" do
        run_generator ["product_sync"]

        assert_file "app/data_flows/product_sync_flow.rb" do |content|
          assert_match(/class ProductSyncFlow/, content)
          assert_match(/require 'active_data_flow'/, content)
          assert_match(/def self\.register/, content)
          assert_match(/def transform\(data\)/, content)
          assert_match(/name: "product_sync_flow"/, content)
        end
      end

      test "generator uses custom scope option" do
        run_generator ["product_sync", "--scope=Product.active"]

        assert_file "app/data_flows/product_sync_flow.rb" do |content|
          assert_match(/scope: Product\.active/, content)
        end
      end

      test "generator uses custom batch_size option" do
        run_generator ["product_sync", "--batch-size=50"]

        assert_file "app/data_flows/product_sync_flow.rb" do |content|
          assert_match(/batch_size: 50/, content)
        end
      end

      test "generator uses custom model_class option" do
        run_generator ["product_sync", "--model-class=ProductExport"]

        assert_file "app/data_flows/product_sync_flow.rb" do |content|
          assert_match(/model_class: ProductExport/, content)
        end
      end

      test "generator uses class name as default model_class" do
        run_generator ["product_sync"]

        assert_file "app/data_flows/product_sync_flow.rb" do |content|
          assert_match(/model_class: ProductSync/, content)
        end
      end

      test "generator includes source template" do
        run_generator ["product_sync"]

        assert_file "app/data_flows/product_sync_flow.rb" do |content|
          assert_match(/ActiveDataFlow::Connector::Source::ActiveRecordSource\.new/, content)
          assert_match(/scope:/, content)
          assert_match(/scope_params:/, content)
          assert_match(/batch_size:/, content)
        end
      end

      test "generator includes sink template" do
        run_generator ["product_sync"]

        assert_file "app/data_flows/product_sync_flow.rb" do |content|
          assert_match(/ActiveDataFlow::Connector::Sink::ActiveRecordSink\.new/, content)
          assert_match(/model_class:/, content)
        end
      end

      test "generator includes runtime template" do
        run_generator ["product_sync"]

        assert_file "app/data_flows/product_sync_flow.rb" do |content|
          assert_match(/ActiveDataFlow::Runtime::Heartbeat\.new/, content)
        end
      end

      test "generator handles scope_params array option" do
        run_generator ["product_sync", "--scope-params=active", "published"]

        assert_file "app/data_flows/product_sync_flow.rb" do |content|
          assert_match(/scope_params: \["active", "published"\]/, content)
        end
      end

      test "generator creates file with correct naming convention" do
        run_generator ["user_export"]

        assert_file "app/data_flows/user_export_flow.rb" do |content|
          assert_match(/class UserExportFlow/, content)
          assert_match(/name: "user_export_flow"/, content)
        end
      end

      test "generator includes transform method stub" do
        run_generator ["product_sync"]

        assert_file "app/data_flows/product_sync_flow.rb" do |content|
          assert_match(/private/, content)
          assert_match(/def transform\(data\)/, content)
          assert_match(/# TODO: Implement your transformation logic here/, content)
        end
      end
    end
  end
end

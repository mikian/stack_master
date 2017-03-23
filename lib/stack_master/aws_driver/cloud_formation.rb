module StackMaster
  module AwsDriver
    class CloudFormation
      extend Forwardable

      def set_region(region)
        @region = region
        @cf = nil
      end

      def_delegators :cf, :create_change_set,
                          :execute_change_set,
                          :delete_change_set,
                          :delete_stack,
                          :cancel_update_stack,
                          :describe_stack_resources,
                          :get_template,
                          :get_stack_policy,
                          :update_stack,
                          :create_stack

      def describe_change_set(options)
        retry_with_backoff do
          cf.describe_change_set(options)
        end
      end

      def describe_stacks(options)
        retry_with_backoff do
          cf.describe_stacks(options)
        end
      end

      def validate_template(options)
        retry_with_backoff do
          cf.validate_template(options)
        end
      end

      def describe_stack_events(options)
        retry_with_backoff do
          cf.describe_stack_events(options)
        end
      end

      private

      def cf
        @cf ||= Aws::CloudFormation::Client.new(region: @region)
      end

      def retry_with_backoff
        delay       = 1
        max_delay   = 30
        begin
          yield
        rescue Aws::CloudFormation::Errors::Throttling => e
          if e.message =~ /Rate exceeded/
            sleep delay
            delay *= 2
            if delay > max_delay
              delay = max_delay
            end
            retry
          end
        end
      end
    end
  end
end

module StackMaster
  class StackDefinition
    include Virtus.value_object(strict: true, required: false)

    values do
      attribute :region, String
      attribute :stack_name, String
      attribute :cf_stack_name, String
      attribute :template, String
      attribute :tags, Hash
      attribute :notification_arns, Array[String]
      attribute :base_dir, String
      attribute :secret_file, String
      attribute :stack_policy_file, String
      attribute :additional_parameter_lookup_dirs, Array[String]
    end

    def cf_stack_name
      super || @_cf_stack_name ||= begin
        if stack_name[0] == '-'
          stack_name[1..-1]
        else

          prefix = case tags['Environment']
          when /production/i
            'prd'
          when /staging/i
            'stg'
          when /qa/i
            'qa'
          when /dev.*/i
            'dev'
          when /test.*/i
            'tst'
          else
            nil
          end

          [prefix, stack_name].compact.join('-')
        end
      end
    end

    def template_file_path
      File.join(base_dir, 'templates', template)
    end

    def parameter_files
      [
        *common_parameter_file_paths,
        default_parameter_file_path,
        region_parameter_file_path,
        *additional_parameter_lookup_file_paths,
      ]
    end

    def stack_policy_file_path
      File.join(base_dir, 'policies', stack_policy_file) if stack_policy_file
    end

    private

    def additional_parameter_lookup_file_paths
      additional_parameter_lookup_dirs.map do |a|
        File.join(base_dir, 'parameters', a, "#{underscored_stack_name}.yml")
      end
    end

    def region_parameter_file_path
      File.join(base_dir, 'parameters', "#{region}", "#{underscored_stack_name}.yml")
    end

    def default_parameter_file_path
      File.join(base_dir, 'parameters', "#{underscored_stack_name}.yml")
    end

    def common_parameter_file_paths
      paths = additional_parameter_lookup_dirs.map do |a|
        File.join(base_dir, 'parameters', "#{a}.yml")
      end
      paths << File.join(base_dir, 'parameters', "#{region}.yml")
    end

    def underscored_stack_name
      stack_name.gsub('-', '_')
    end
  end
end

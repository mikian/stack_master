module StackMaster
  class StackDefinition
    attr_accessor :region,
                  :stack_name,
                  :cf_stack_name,
                  :template,
                  :tags,
                  :role_arn,
                  :notification_arns,
                  :base_dir,
                  :template_dir,
                  :secret_file,
                  :stack_policy_file,
                  :additional_parameter_lookup_dirs,
                  :s3,
                  :files,
                  :compiler_options

    include Utils::Initializable

    def initialize(attributes = {})
      @additional_parameter_lookup_dirs = []
      @compiler_options = {}
      @notification_arns = []
      @s3 = {}
      @files = []
      super
      @template_dir ||= File.join(@base_dir, 'templates')
    end

    def ==(other)
      self.class === other &&
        @region == other.region &&
        @stack_name == other.stack_name &&
        @cf_stack_name == other.cf_stack_name &&
        @template == other.template &&
        @tags == other.tags &&
        @role_arn == other.role_arn &&
        @notification_arns == other.notification_arns &&
        @base_dir == other.base_dir &&
        @secret_file == other.secret_file &&
        @stack_policy_file == other.stack_policy_file &&
        @additional_parameter_lookup_dirs == other.additional_parameter_lookup_dirs &&
        @s3 == other.s3 &&
        @compiler_options == other.compiler_options
    end

    def cf_stack_name
      @cf_stack_name || @_cf_stack_name ||= begin
        if stack_name[0] == '-'
          stack_name[1..-1]
        else
          prefix = case tags['AppTier']
                   when /production/i
                     'prod'
                   when /staging/i
                     'stg'
                   when /qa/i
                     'qa'
                   when /dev.*/i
                     'dev'
                   when /test.*/i
                     'test'
          end
          [
            (tags['Owner'] && tags['Owner'].downcase),
            prefix,
            stack_name
          ].compact.join('-')
        end
      end
    end

    def template_file_path
      File.expand_path(File.join(template_dir, template))
    end

    def files_dir
      File.join(base_dir, 'files')
    end

    def s3_files
      files.each_with_object({}) do |file, hash|
        path = File.join(files_dir, file)
        hash[file] = {
          path: path,
          body: File.read(path)
        }
      end
    end

    def s3_template_file_name
      return template if ['.json', '.yaml', '.yml'].include?(File.extname(template))
      Utils.change_extension(template, 'json')
    end

    def parameter_files
      [ default_parameter_file_path, region_parameter_file_path, additional_parameter_lookup_file_paths, common_parameter_file_path ].flatten.compact.reverse
    end

    def stack_policy_file_path
      File.join(base_dir, 'policies', stack_policy_file) if stack_policy_file
    end

    def s3_configured?
      !s3.nil?
    end

    private

    def additional_parameter_lookup_file_paths
      return unless additional_parameter_lookup_dirs
      additional_parameter_lookup_dirs.map do |a|
        Dir.glob(File.join(base_dir, 'parameters', a, "#{underscored_stack_name}.y*ml"))
      end
    end

    def region_parameter_file_path
      Dir.glob(File.join(base_dir, 'parameters', region.to_s, "#{underscored_stack_name}.y*ml"))
    end

    def default_parameter_file_path
      Dir.glob(File.join(base_dir, 'parameters', "#{underscored_stack_name}.y*ml"))
    end

    def common_parameter_file_path
      paths = []
      if additional_parameter_lookup_dirs
        paths += additional_parameter_lookup_dirs.map do |a|
          File.join(base_dir, 'parameters', "#{a}.yml")
        end
      end

      paths << File.join(base_dir, 'parameters', "#{region}.yml")

      paths
    end

    def underscored_stack_name
      stack_name.tr('-', '_')
    end
  end
end

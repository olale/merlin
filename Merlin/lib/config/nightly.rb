require 'configuration'
require 'config/src'

module TC::Conf
  class Nightly < YamlConf

    class TargetMachineConfig < YamlConf

      def initialize(c)
        @conf=c
      end

      def host
        "\\\\"+self['host']
      end

      def host_name
        host.gsub '\\',''
      end

      # Return parameters specific to a MSI package on the current
      # host
      def parameters_for(msi_file)
        eq_filename = lambda {|h| h['file'] == File.basename(msi_file) }
        has_param = @conf.has_key?('parameters') && @conf['parameters'].any?(&eq_filename)
        has_param ? @conf['parameters'].first(&eq_filename)['parameters'] : ""
      end

    end

    def reset!
      super
      @output_packages=nil
    end

    # Find all msi files built in the product directory of <product_name> 
    def output_packages(product_name)
      @output_packages ||= {} # Create hash table unless it exists
      @output_packages[product_name] ||= conf[product_name]['output_packages'].collect do |msi_file| 
        glob_path_pattern = "#{Src.project_root(product_name).from_win_path}/**/#{msi_file}"
        # Reject packages built in Debug settings
        Dir[glob_path_pattern].find {|path| !(/Debug/i =~ path) }
      end
    end

    def target_machine_hashes_for(product)
      self['target_machines'].select {|config| config['app'] == product }
    end

    def target_machines(product)
      target_machine_hashes_for(product).collect { |c| TargetMachineConfig.new c }
    end

    def db_configs(product_name)
      config_class=Struct.new :backup_dir, :username, :server, :db, :password, :file_name
      target_machine_hashes_for(product_name).collect do |c| 
        config_class.new.tap do |db_config| 
          db_config.backup_dir = c['backup_dir']
          db_config.username   = c['db_user']
          db_config.password   = c['db_password']
          db_config.server     = c['db_server']
          db_config.db         = c['db_name']
          
          db_config.file_name  = "DB Config from config/nightly.yml"
        end
      end
    end

  end
end

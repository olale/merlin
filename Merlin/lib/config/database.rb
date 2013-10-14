require 'configuration'
require 'config/environment'
require 'ostruct'

class TC::Conf::Database < TC::Conf::YamlConf
  include TC::Conf

  class DBConf < YamlConf

    attr_reader :file_name
    
    def initialize(arg)
      @file_name=arg
      if arg.class==String
        @conf=Psych.load_file file_name
      elsif arg.class==OpenStruct
        @file_name="Master DB config"
        @conf=arg.marshal_dump.inject({}) {|memo,(k,v)| memo[k.to_s] = v; memo}
      elsif arg.class==Hash
        @file_name="dynamic DB config"
        @conf=arg
      else
        raise "Unknown config type: #{arg.class}"
      end
    end

    def dump_root
      File.join(dump_path,conf['db'])
    end

    def dump_path
      conf['dump_path'] ||= default_dump_path
    end

    def backup_dir
      conf['backup_dir'] ||= default_backup_dir
    end

    def default_dump_path
      default_path=File.join(Etc.systmpdir,'sql_dumps')
      Common.logger.warn "No 'dump_path' given in #{@file_name}, using default: #{default_path}"
      default_path
    end

    def default_backup_dir
      default_path=File.join(Etc.systmpdir,"sql_backups")
      Common.logger.warn "No 'backup_dir' given in #{@file_name}, using default: #{default_path}"
      default_path
    end
        
  end

  def self.master_config(product=Environment.product)
    master_config=DBConf.new OpenStruct.new(self['master'][product])
    master_config.db=master_config.db.expand_template product
    master_config.dump_path= TC.new_dir_dest(product) # File.join(Conf::Src.project_root(product),Sql.db_dump_dir)
    master_config
  end

  def self.variant_configs(product=Environment.product)
    variant_list=self['master'][product]['variants']
    master_conf=master_config(product)
    variant_list.globs_to_paths(CONFDIR,product).collect do |f| 
      conf=DBConf.new f
      conf.dump_path=master_conf.dump_path
      conf
    end    
  end

  def self.variant_config(product=Environment.product,variant)
    variants=variant_configs(product)
    variant_names=variants.collect {|c| File.basename(c.file_name,".yml") }
    variant_config=variants.find { |c| /#{variant}\.yml$/ =~ c.file_name }
    raise "no variant '#{variant}' found, available variants are '#{variant_names.join(',')}'" unless variant_config
    variant_config
  end

  def self.configs(product=Environment.product,env=Environment.env)
    self['databases'].globs_to_paths(CONFDIR,product,env).collect { |f| DBConf.new f }
  end
  
  def self.db_config(f)
    config_file = File.exist?(f) ? f : "#{CONFDIR}/database/#{f}.yml"
    Common.logger.error "No matching config file {#{f},#{CONFDIR}/database/#{f}.yml} found " unless File.exist? config_file
    DBConf.new(config_file)          
  end
  
end

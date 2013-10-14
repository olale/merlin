require 'db/db'

module TC

  class Create < Db

    @@dep_pattern1 = /Invalid object name '(.*\.)?(\w+)'/
    @@dep_pattern2 = /Cannot find either column "(.*)" or the user-defined function or aggregate "(.*)"/


    attr_accessor :dump_root, :product, :variant_root, :callback

    def initialize(conf,product)
      super(conf)
      @script_order = Conf::Sql.script_order
      @product=product
      @abort_on_error,Conf::Build.abort_on_error=Conf::Build.abort_on_error,false
      @log_level,Common.logger.level=Common.logger.level,Logger::FATAL
    end
    
    def dump_root
      @dump_root||=Conf::Database.master_config(product).dump_root
    end

    def try_sql(script)
      result = sql(script)[:stdout]
      
      if @@dep_pattern1 =~ result
        dependency = @@dep_pattern1.match(result)[2]
      elsif @@dep_pattern2 =~ result
        dependency = @@dep_pattern2.match(result)[2]
      end
      if dependency
        Common.logger.info "#{File.basename(script)} requires #{dependency}"
        dep_file = find_sql(dependency)
        Common.logger.info " ... loading #{dep_file}"
        try_sql(dep_file)
        try_sql(script)
      end
    end

    def find_sql(name)
      pattern = /#{Regexp.quote(name)}/
      sql_files.find { |file| pattern =~ file }
    end

    def sql_files
      @sql_files ||= Conf::Sql.script_order.collect_concat do |pattern| 
        path = "#{dump_root}/#{pattern}".gsub(/\\/,"/")
        FileList[path]
      end
    end

    # The number of times +callback+ will be called, which will equal
    # the number of SQL files + 1, to account for the last step of the
    # upgrade process when the message "Done!" is submitted to the
    # callback instead of the file name
    def steps
      sql_files.length+1
    end

    # We try to do things in the right order automatically, by
    # scanning for error messages, finding a file that contains a
    # definition of the object referred to in the error message,
    # loading that file and trying again
    def run
      # We always create a fresh copy
      if db_exists?
        drop
      end
      create
      # Authentication must be set up prior to creation.
      create_login product
      if sql_files.empty?
        raise "No installation files found in #{dump_root}, wrong directory?"
      else
        sql_files.each do |file|
          callback.call file if callback
          try_sql(file)
        end
      end
      callback.call "Done!" if callback
      Conf::Build.abort_on_error=@abort_on_error
      Common.logger.level=@log_level
      Common.logger.info("Installed #{product}@#{setting} successfully")      
    end

  end

end

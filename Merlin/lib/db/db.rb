require 'tcfileutils'

module TC
  class Db

    include Common
    attr_reader :db, :server, :user,:password, :use_master, :config_file, :product, :version

    def initialize(conf,product=nil)
      @db=conf.db
      @server=conf.server
      @user = conf.username
      @password = conf.password
      @config_file=conf.file_name
      @product=product
    end
        
    def sql(script)
      raise "No SQL file given" unless script
      raise "Invalid SQL file" unless File.exist?(script)
      script=script.to_win_path
      params = ""
      params << "-b "
      params << %Q[-i "#{script}" ]      
      params << "-f 65001 " # Always assume UTF-8 files
      params << %Q[-S #{server} ]
      params << "-d #{db} " unless use_master
      if user.to_s=='' # nil or empty
        params << "-E"
      else
        params << "-U #{user} -P #{password}"
      end
      Command.run(Conf::Command.sqlcommand, params)
    end
    
    def setting
      "#{server}/#{db}"
    end

    def config_copy
      config_copy=OpenStruct.new
      config_copy.server=server
      config_copy.db=db
      config_copy.user=user
      config_copy.password=password
      config_copy
    end

    def cn(server,db,user,pwd)
      if user && pwd
        auth=%Q[User ID=#{user};Password=#{pwd};Trusted_Connection=False;]
      else
        auth=%Q[Trusted_Connection=True;]
      end
      %Q["Server=#{server};Database=#{db};#{auth}"]
    end

    # We assume scripts that return scalar results to stdout
    def get_result(sql_script)
      output = sql(sql_script)[:stdout]
      lines = output.split("\n").collect { |l| l.strip }
      lines.reject! { |l| /^-+$/ =~ l || /rows affected/ =~ l }
      lines[1]
    end

    def get_version(product)
      get_result File.join(SQLDIR,"get_version_#{product}.sql")
    end

    def set_version(product,version)
      @version=version
      version_script = TCFileUtils.file_from_template("#{SQLDIR}/set_version_#{product}.sql.erb",self)
      sql version_script
    end

    def using_master
      old_use_master=@use_master
      @use_master=true
      result=yield
      @use_master=old_use_master
      result
    end

    def script_ok?(script)
      get_result(script)=="1"
    end

    def db_exists?
      using_master do
        script = TCFileUtils.file_from_template("#{SQLDIR}/check_db_exists.sql.erb",self)
        script_ok? script
      end
    end

    def create_login(product)
      sql File.join(SQLDIR,"create_login_#{product}.sql")
    end
    
    def drop
      using_master do
        script = TCFileUtils.file_from_template("#{SQLDIR}/drop_db.sql.erb",self)
        sql script
      end
    end
    
    def create
      using_master do
        script = TCFileUtils.file_from_template("#{SQLDIR}/create_db.sql.erb",self)
        sql script
      end
    end

  end
end

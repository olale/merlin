require 'db/db'
require 'tfs'
require 'fileutils'

module TC

  class DbUpgrade < Db

    # rerun_upgrades = Should we run upgrades to version X even if the current version is X? 
    attr_accessor :callback, :basedir, :old_version, :rerun_upgrades

    @@compatibility_error = "Too low compatibility level. "+
      "Ensure compatibility level is set to at least SQL Server 2008 (100)"

    # Only run upgrades once in production
    def rerun_upgrades
      @rerun_upgrades ||= (Conf::Environment.setting!=Conf::Environment::Settings::PRODUCTION)
    end

    def self.create(conf,product)
      (Conf::Sql.upgrade_mode(product)=="legacy" ? LegacyUpgrade : ModernUpgrade).new(conf,product)
    end

    def initialize(conf,product)
      super(conf,product)
      @basedir=Conf::Src.project_root(product)
      @backup = Backup.new(conf)
    end

    def steps
      # The last step in the upgrade process yields "Done!"
      num_upgrade_files+1
    end

    def set_version(version)
      super(product,version)
    end
    
    def get_version
      super(product)
    end

    def compatibility_level_ok?
      script_ok? TCFileUtils.file_from_template("#{SQLDIR}/check_compatibility_level.sql.erb",self)
    end

    def run
      @old_version = get_version
      if !up_to_date? || rerun_upgrades
        raise @@compatibility_error unless compatibility_level_ok?
        @backup.run
        begin        
          upgrade do |file|
            callback.call file if callback
          end
          callback.call "Done!" if callback
          new_version = get_version
          Common.logger.info("Upgraded #{product}@#{setting} from #{old_version} to #{new_version}")
          if server.local_address?
            FileUtils.rm @backup.bak_file
          else
            Common.logger.info("Backup file #{@backup.bak_file.to_win_path} on #{server} may now be removed")
          end
        rescue Exception => e
          # Rescue both failed upgrades and failed upgrade tests
          Common.logger.warn "Upgrade failed (#{e.message}), rolling back #{product}@#{setting} to v.#{old_version}"
          rollback
          Common.logger.error e.message
        end
      else
        Common.logger.info("#{product}@#{setting} already upgraded to latest version (#{old_version})")    
      end
    end

    def rollback
      conf = OpenStruct.new
      conf.server=server
      conf.db=db
      conf.username=user
      conf.password=password
      conf.bak_file=@backup.bak_file
      Restorer.new(conf,product).run
    end

  end

  class ModernUpgrade < DbUpgrade

    def connection_hash
      h = {
        :adapter  => "sqlserver",
        :database => db,
        :login_timeout => 3
      }
      # Use the dataserver format, with mssqlserver as the default
      # instance name
      if /\\/ =~ server
        h[:dataserver]=server
      else
        h[:dataserver]=server+"\\mssqlserver"
      end
      
      if user
        h[:username] = user
        h[:password] = password        
      end
      return h
    end

    def initialize(conf,product)
      super(conf,product)
      ActiveRecord::Base.pluralize_table_names = false      
      ActiveRecord::Base.establish_connection(connection_hash)
    end

    def filtered_upgrade_files
      version=get_version
      upgrade_files.select do |f|
        # Re-run the upgrades for the latest version if the db has the current version
        rerun_current_upgrades = (rerun_upgrades && up_to_date? && (migration_version(f).version_gte version))
        rerun_current_upgrades ||
        (migration_version(f).version_gt version)
      end
    end

    def configured_upgrade_files
      @configured_upgrade_files||=FileList[File.join(@basedir,Conf::Sql.upgrade_files).from_win_path]
    end

    # Migration files are in directories with version numbers
    def upgrade_files
      @upgrade_files ||= configured_upgrade_files.select { |f| /(\d+\.)+/ =~ migration_version(f) }.sort
    end

    # Are there no upgrade scripts pertaining to a
    # higher version?
    def up_to_date?
      upgrade_files.select {|f| migration_version(f).version_gt version}.empty?
    end

    # We assume that every upgrade file is of the form
    # ".../Upgrade/1.2.3/001_some_name.rb"
    def upgrade_dir
      raise "No upgrade files" unless upgrade_files
      (Pathname.new(upgrade_files.first)+"../../").to_s
    end

    def tests
      @tests||=FileList[upgrade_dir+"/test/*.{rb,sql}"].collect { |test_file| Verifier.new(self,test_file) }
    end

    def sql?(file)
      file.end_with? ".sql"
    end

    def ruby?(file)
      file.end_with? ".rb"
    end

    def migration_version(file)
      File.basename((Pathname.new(file)+"..").to_s)
    end

    def num_upgrade_files
      filtered_upgrade_files.length
    end

    def run_tests(version)
      applicable_tests=tests.select do |t| 
        applicable = t.applicable_to?(version)
        applicable &&= yield t if block_given?
        applicable
      end
      applicable_tests.each { |t| t.run }
    end

    def upgrade
      @last_version=old_version
      # Ensure that Ruby migrations have access to a common path for
      # included files
      $LOAD_PATH.unshift(upgrade_dir)
      filtered_upgrade_files.each do |file|
        this_version=migration_version(file)
        if @last_version != this_version
          # Only run ruby tests after intermediate upgrade steps
          run_tests @last_version do |t| 
            ruby? t.file
          end
        end

        # yield to block so we can show what upgrade file is processed
        # currently
        yield file

        if sql?(file)
          sql(file.to_win_path)
        elsif ruby?(file)
          Migrator.new(file).run
        else
          Common.logger.warn("Unknown upgrade file type: #{file}")
        end
        @last_version=this_version
      end
      # Run all applicable tests after the last upgrade step
      run_tests @last_version
      set_version @last_version
    end

  end

  class LegacyUpgrade < DbUpgrade
    
    def initialize(conf,product)
      super(conf,product)
      @basedir = Conf::Sql.install_dir(product)
      @version_pattern = /(\d+\.\d+\.\d+(\.\d+)?)_(\d+\.\d+\.\d+(\.\d+)?)/
    end

    def num_upgrade_files
      get_appropriate_upgrade_files(upgrade_files).length
    end
    
    # Are there no upgrade scripts from the current version to a
    # higher version?
    def up_to_date?
      @version||=get_version
      updates_to_higher_version=upgrade_files.select {|f| /#{@version}_(\d+\.)+/ =~ f }
      updates_to_higher_version.empty?
    end

    def version_file?(file)
      @version_pattern =~ file
    end

    def migration_version(file)
      @version_pattern.match(file)[3]
    end
    
    def get_appropriate_upgrade_files(upgrade_files)
      version=get_version
      upgrade_files.select do |f| 
        # Select all files that are not version-specific upgrades
        !version_file?(f) || 
        # And those version upgrades that are appropriate for the
        # current version of the database. We run all upgrades for the
        # current version if the db is up to date, or we run upgrades
        # to higher versions if the db is out of date.
        ((rerun_upgrades && up_to_date? && (migration_version(f).version_gte version)) ||
         (migration_version(f).version_gt version))
      end
    end

    def upgrade_files
      @upgrade_files ||= Conf::Sql.install_files(product).collect_concat do |file_pattern|
        FileList[File.join(@basedir,file_pattern).from_win_path]
      end      
    end

    def upgrade
      get_appropriate_upgrade_files(upgrade_files).each do |sql_file|
        yield sql_file
        sql sql_file
      end
    end

  end

end

require 'db/db'
require 'tcfileutils'
require 'fileutils'

module TC

  class Backup < Db
    
    attr_reader :backup_dir, :bak_file

    def initialize(conf)
      super(conf)
      @backup_dir=conf.backup_dir
      @use_master=true
    end

    def run
      if ! backup_dir
        Common.logger.error "'#{config_file}' has no 'backup_dir', skipping"
      else
        FileUtils.mkdir_p backup_dir
        suffix=Time.now.strftime("%Y%m%d_%H%M")      
        @bak_file=(Pathname.new(backup_dir)+"#{db}_#{suffix}.bak").to_s.to_win_path
        backup_script = TCFileUtils.file_from_template("#{SQLDIR}/backup.sql.erb",self)
        sql backup_script
        Common.logger.info "backed up #{setting} to #{@bak_file}"
      end
    end

  end

end

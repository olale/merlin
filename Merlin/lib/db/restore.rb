require 'db/db'
require 'tcfileutils'

module TC

  class Restorer < Db
    
    attr_reader :bak_file, :config_file

    def initialize(conf,product)
      super(conf,product)
      @bak_file=conf.bak_file.to_win_path
    end

    def run        
      if @bak_file
        restore_file = TCFileUtils.file_from_template("#{SQLDIR}/restore.sql.erb",self)
        using_master { sql restore_file }
        create_login product
        Common.logger.info "restored #{setting} from #{bak_file}"
      else
        Common.logger.warn "no backup file specified in #{config_file} for #{setting}, skipping"
      end
    end

  end

end

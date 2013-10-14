require 'test_base'
require 'db'
require 'tfs'
require 'config/build'

class CreateIntegrationTest < TestBase

  def db_config
    Conf::Database.configs(product,env).first
  end

  def setup
    basedir=File.join(File.dirname(__FILE__),"files")
    master_db_dump_path=File.join(basedir,
                                  Conf::Sql.db_dump_dir,
                                  db_config.db)
    conf=OpenStruct.new
    conf.server=db_config.server
    conf.db="CREATED_DB"
    conf.user=db_config.user
    conf.password=db_config.password
    @creator=Create.new(conf,product)
    @creator.dump_root=master_db_dump_path
  end

  def teardown
    if @creator.db_exists?
      @creator.drop 
    end
  end

  def test_sql_files
    refute_empty @creator.sql_files
  end
  
  def test_create
    begin
      @creator.run
    rescue Exception => e
      # Exceptions will result in failure, everything else is
      # considered a success
      flunk e.message
    end
  end

  def test_variants
    # Verify that we can dump and later use variants
    # begin
    #   MasterDumper.dump_variants product
    # rescue Exception => e
    #   flunk e.message
    # ensure
    #  #  TFS.undo ...
    # end
  end
  
end

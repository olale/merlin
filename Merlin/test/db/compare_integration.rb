require 'test_base'
require 'db'
require 'ostruct'
require 'fileutils'

class ComparisonIntegrationTest < TestBase

  def setup
    @db_config=Conf::Database.configs(product,env).first
    @master_config=OpenStruct.new
    @master_config.server=@db_config.server
    @master_config.db="TEST_MASTER_#{product}"
    @master_config.user=@db_config.user
    @master_config.password=@db_config.password
    @master_config.bak_file=@db_config.bak_file
    @master_config.file_name="TEST_MASTER_CONFIG"
    @master_config.backup_dir=File.join(File.dirname(__FILE__),"backups")
    FileUtils.mkdir_p @master_config.backup_dir
    @master_config.dump_path=File.join(File.dirname(__FILE__),"dumps")
    @master_config.dump_root=File.join(@master_config.dump_path,
                                       @master_config.db)
    @db_config.dump_path=File.join(File.dirname(__FILE__),"dumps")
    @db_config.dump_root=File.join(@db_config.dump_path,
                                   @db_config.db)

  end

  def teardown
    FileUtils.rm_rf @master_config.backup_dir
  end

  def load_and_migrate_master
    # Restore the two database configurations
    Restorer.new(@master_config,product).run
    Restorer.new(@db_config    ,product).run
    
    # migrate the master
    master_upgrader = ModernUpgrade.new(@master_config,product)    
    master_upgrader.basedir=File.join(File.dirname(__FILE__),"files")
    master_upgrader.set_version("1.0")
    master_upgrader.run
  end

  # Verify that there is a difference between the db structure after a
  # DB migration using string diffs
  def test_diff_different
    diff_comparer=DiffCompare.new @db_config,product
    diff_comparer.master_config=@master_config
    diff_comparer.dump=false
    diff=diff_comparer.run
    refute diff_comparer.equal?, "there should be differences between the two DB structure dumps"
  end

  # Verify that there is a difference when using the OCDB Diff tool
  def test_ocdb_different
    load_and_migrate_master
    comparer=OCDBCompare.new(@db_config,product)
    comparer.master_config=@master_config
    diff=comparer.run
    refute comparer.equal?, "There should be structure differences after a master migration"
    assert_match(/CREATE PROCEDURE \[dbo\]\.\[get_users\]/, 
                 diff, 
                 "there should be a CREATE PROCEDURE statement in the DB Diff")
  end

end

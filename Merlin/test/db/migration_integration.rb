require 'test_base'
require 'db'
require 'tfs'

class MigrationIntegrationTest < TestBase

  def db_config
    @db_config ||= Conf::Database.configs(product,env).first
    refute_nil @db_config
    @db_config
  end

  def setup
    @basedir=File.join(File.dirname(__FILE__),"files")
    @master_db_dump_path=File.join(@basedir,Conf::Sql.db_dump_dir)
    @config=db_config
    @config.dump_path=@master_db_dump_path
    @upgrader = ModernUpgrade.new(@config,product)    
    @upgrader.basedir=File.join(File.dirname(__FILE__),"files")
    @upgrader.set_version("1.0")
  end

  def load_db
    Restorer.new(db_config,product).run
  end

  def teardown
    # Drop DB?
  end

  def test_establish_connection
    assert_respond_to ActiveRecord::Base, :establish_connection
  end

  def test_migration_count
    assert_equal 5, @upgrader.upgrade_files.length
  end

  # Verify that migrations are processed in the right order
  def test_migration_order
    assert_match /1\.1/, @upgrader.upgrade_files[0]
    assert_match /1\.1/, @upgrader.upgrade_files[1]
    assert_match /1\.2/, @upgrader.upgrade_files[2]
    assert_match /1\.2/, @upgrader.upgrade_files[3]
    assert_match /2\.0/, @upgrader.upgrade_files[4]
  end

  # Given a version number, verify that only migrations that are
  # relevant to perform for a db of that version are selected
  def test_selected_migrations
    @upgrader.set_version("1.2")
    upgrade_files=@upgrader.filtered_upgrade_files
    assert_equal "1.2", @upgrader.get_version, "The DB should have version 1.2 when selecting migration steps"
    assert_equal 1, upgrade_files.length, "there should be 1 upgrade file later than v.1.2, but I found #{upgrade_files.join(', ')}"
  end

  # Verify the migration. Included in the migration are also test
  # steps
  def test_migration
    load_db
    @upgrader.set_version("1.0")
    @upgrader.run
    assert_equal "2.0", @upgrader.get_version
  end

  # When we perform migration tasks, we want to log the changes to the
  # DB structure by checking in both migration scripts and the
  # modifications to the master structure, to keep the history of both
  def test_dump_migrate
    load_db
    TFS.undo @master_db_dump_path
    @upgrader.set_version("1.0")
    @upgrader.run
    dumper=MasterDumper.new @config,product
    dumper.dry_run=true
    changes=dumper.run
    # There should be three new files to add
    assert_match /add.*StoredProcedures\\dbo\.get_users/, changes
    assert_match /add.*Tables\\dbo\.Users/, changes
    assert_match /add.*PrimaryKeys\\dbo\.Users/, changes
    TFS.undo @master_db_dump_path
  end
  
end

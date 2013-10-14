require 'test_base'

class UpgradeTest < TestBase

  def setup
    # info = UpgradeInfo.new
    # info.db = "Test"
    # info.bak_file = 
    # restore_script = tmp(File.join(SQLDIR,"restore.sql.erb"),self)
  end

  def upgrader_verify(&block)
    products.each do |product|
      multi_upgrade = MultiDb.upgrade(Conf::Database.configs(product,Conf::Environment::Settings::TEST),
                                      product)
      multi_upgrade.actions.each do |a|
        yield a
      end
    end

  end

  def test_script_order
    upgrader_verify do |u|
      assert u.upgrade_files.any?, "there should be upgrade scripts for '#{u.product}'"
    end
  end

  def test_basedir_ok
    upgrader_verify do |u|
      assert File.exists?(u.basedir), "expected DB base directory #{u.basedir} for '#{u.product}'"
    end
  end

  def test_upgrade_files_exist
    upgrader_verify do |u|
      u.upgrade_files.each do |file| 
        assert File.exists?(file), "missing DB upgrade file #{file} for '#{u.product}'"
      end
    end
  end

end

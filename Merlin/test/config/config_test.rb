# -*- coding: utf-8 -*-
Dir["#{LIBDIR}/config/*.rb"].each do |path|
  file=File.basename(path, File.extname(path))
  require 'config/'+file
end

# Assert that all necessary keys exist and have sensible 
# values in the config files
class ConfigTest < TestBase
  
  def test_sql_install_config
    products.each do |product|
      assert(!Conf::Sql[product].nil?, 
             "There should be a '#{product}' entry in config/sql.yml")
      assert(Conf::Sql[product].has_key?('install'), 
             "there should be a '#{product}/install' entry in sql.yml")
      assert(Conf::Sql[product]['install'].has_key?('dir'), 
             "there should be a '#{product}/install/dir' entry in sql.yml")
      assert(Conf::Sql[product]['install'].has_key?('files'), 
             "there should be a '#{product}/install/files' entry in sql.yml")
    end
  end

  def test_sql_install_files_exist
    products.each do |product|
      files=Conf::Sql.install_files(product)
      dir=Conf::Sql.install_dir(product)
      assert(File.exists?(dir),"#{dir} should exist")
      
      assert !files.nil?, 
      "#{product} should have SQL files for upgrade defined"

    end
    
  end

  def test_legacy_upgrade_install_files
    products.each do |product|
      upgrader = LegacyUpgrade.new(Conf::Database.configs(product,
                                                          Conf::Environment::Settings::TEST)[0], 
                                   product)
      assert(upgrader.upgrade_files.any?, "#{product} should have DB upgrade files in #{upgrader.basedir}")
    end
  end

  def test_upgrade_files_exist
    products.each do |product|
      project_root = Conf::Src.project_root(product)
      if Conf::Sql.legacy?(product)
        install_config = Conf::Sql[product]['install']
        legacy_install_root = File.join(project_root,install_config['dir'])
        assert(File.exists?(legacy_install_root), 
               "#{product} should have valid DB installation directory #{legacy_install_root} in sql.yml")
      else
        upgrade_dir=Conf::Sql.upgrade_dir(product)
        assert(File.exists?(upgrade_dir), 
               "#{product} should have DB upgrade directory #{upgrade_dir} in sql.yml")
      end
    end
  end

  def test_product_setting
    p=Conf::Environment.product
    assert(Conf::Environment.products.include?(p), 
           "selected product '#{p}' must be in list of available products")
  end

  def test_env_setting
    p=Conf::Environment.env
    assert(['development', 'production'].include?(p), 
           "selected environment '#{p}' must be one of ['development', 'production']")
  end
  
  def test_libdir
    assert(LIBDIR != nil, "there should be a variable LIBDIR defined")
  end

  def test_vb6_command
    if Conf::Environment.products.include?(Conf::Environment::Products::PLANNING)
      begin
        Conf::Command.vb6
      rescue Exception => e
        flunk e
      end
    end
  end

  def test_devenv_command
    begin
      Conf::Command.devenv
    rescue Exception => e
      flunk e
    end
  end

  def test_mstest_command
      begin
        Conf::Command.mstest_command
      rescue Exception => e
        flunk e
      end
  end

  def test_db_config
    product = Conf::Environment.product
    refute_nil(Conf::Database.configs(product,'test'), 
           "there should be a test db configuration for #{product} as specified in config/database.yml")
  end

  def test_output_packages_exist
    products.each do |product|
      output_packages=Conf::Nightly.output_packages(product)
      refute_empty output_packages
    end
  end

  def test_destination_exists
    products.each do |product|
      dest=Conf::Build.destination(product)
      assert File.exist?(dest), "invalid destination #{dest} in config/build.yml for #{product}"
    end
  end

end

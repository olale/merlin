require 'db'
require 'fileutils'
require 'pathname'
require 'config/sql'
require 'packager'
require 'tfs'

class DBTasks

  class << self

    def copy_files(src_dir,dest_dir)
      src=src_dir.to_win_path.sub(/\\$/,'') # Strip trailing '\' to avoid escaped quotation marks
      dest=dest_dir.to_win_path.sub(/\\$/,'') # Strip trailing '\' to avoid escaped quotation marks
      
      FileUtils.mkdir_p dest_dir    
      Command.run "robocopy", %Q["#{src}" "#{dest}" /E]
    end

    def copy_db_upgrade_scripts(product)
      dest_dir = TC.upgrade_dir_dest product
      mode=Conf::Sql.upgrade_mode product
      if mode=="legacy"
        src_dir=Conf::Sql.install_dir(product)
      else
        src_dir=Conf::Sql.upgrade_dir(product)
      end
      copy_files src_dir,dest_dir
    end

    def copy_db_new_scripts(product,variant=nil)
      dest_dir = TC.new_dir_dest product
      src_dir=Conf::Database.master_config(product).dump_root
      copy_files src_dir,dest_dir
      if variant
        src_dir=Conf::Database.variant_config(product,variant)
        # Overwrite data files from the variant
        copy_files src_dir,dest_dir
      end
    end
    
  end
end

namespace :db do

  desc "Upgrade :db (config/database/:db.yml) to current release of :product (#{Conf::Environment.product})"
  task :upgrade, [:db, :product] do |t,args|
    args.with_defaults :product => Conf::Environment.product
    raise "No :db config given" unless args.db
    upgrader = DbUpgrade.create(Conf::Database.db_config(args.db),args.product)
    upgrader.run
  end

  desc "Restore using :db (config/database/:db.yml) for :product (default #{Conf::Environment.product})"
  task :restore, [:db,:product] do |t,args|
    args.with_defaults :product => Conf::Environment.product
    raise "No :db config given" unless args.db
    restorer = Restorer.new(Conf::Database.db_config(args.db),args.product)
    restorer.run
  end

  desc "Backup using :db (config/database/:db.yml)"
  task :backup, [:db] do |t,args|
    raise "No :db config given" unless args.db
    backup = Backup.new(Conf::Database.db_config(args.db))
    backup.run
  end

  desc "Compare :db (config/database/:db.yml) with master for :product (default #{Conf::Environment.product})"
  task :compare, [:db, :product] do |t,args|
    args.with_defaults :product => Conf::Environment.product
    raise "No :db config given" unless args.db
    comparer = Compare.create(Conf::Database.db_config(args.db),
                              args.product,
                              Conf::Database.comparison_mode)
    comparer.run
  end

  desc "Create :db (config/database/:db.yml) using Master DB structure for :product (default #{Conf::Environment.product})"
  task :create, [:db, :product] do |t,args|
    args.with_defaults :product => Conf::Environment.product
    raise "No :db config given" unless args.db
    creator = Create.new Conf::Database.db_config(args.db), args.product
    creator.run
  end
  

  desc "Dump the structure of :db (config/database/:db.yml) for :product (default #{Conf::Environment.product})"
  task :dump, [:db, :product] do |t,args|
    raise "No :db config given" unless args.db
    dumper = Dumper.new Conf::Database.db_config(args.db), args.product
    dumper.run
  end
  
  namespace :master do

    desc "Dump and track the upgraded master db structure of :product (default #{Conf::Environment.product}) and associated variants (default true)"
    task :dump, [:product, :dump_variants] => :upgrade do |t,args|
      args.with_defaults :product => Conf::Environment.product, :dump_variants => true
      dumper = MasterDumper.new(Conf::Database.master_config(args.product),args.product)
      dumper.run
      if args.dump_variants
        MasterDumper.dump_variants args.product
      end
    end

    desc "Upgrade the master DB for :product (default #{Conf::Environment.product})"
    task :upgrade, [:product] do |t,args|
      args.with_defaults :product => Conf::Environment.product
      upgrader = DbUpgrade.create(Conf::Database.master_config(args.product), args.product)
      upgrader.run
    end

  end

  namespace :multi do
    desc "Upgrade to current release of :product (#{Conf::Environment.product}) in :env (#{Conf::Environment.env})"
    task :upgrade, [:product, :env] do |t,args|
      args.with_defaults :product => Conf::Environment.product, :env => Conf::Environment.env
      upgrader = MultiDb.upgrade(Conf::Database.configs(args.product,args.env), args.product)
      upgrader.run
    end

    desc "Restore from .bak files for :product (#{Conf::Environment.product}) in :env (#{Conf::Environment.env})"
    task :restore, [:product, :env] do |t,args|
      args.with_defaults :product => Conf::Environment.product, :env => Conf::Environment.env
      restorer = MultiDb.restore(Conf::Database.configs(args.product,args.env),args.product)
      restorer.run
    end

    desc "Backup to .bak files for :product (#{Conf::Environment.product}) in :env (#{Conf::Environment.env})"
    task :backup, [:product, :env] do |t,args|
      args.with_defaults :product => Conf::Environment.product, :env => Conf::Environment.env
      backup = MultiDb.backup(Conf::Database.configs(args.product,args.env),args.product)
      backup.run
    end

    desc "Compare databases with master for :product (#{Conf::Environment.product}) in :env (#{Conf::Environment.env})"
    task :compare, [:product, :env] do |t,args|
      args.with_defaults :product => Conf::Environment.product, :env => Conf::Environment.env
      comparer = MultiDb.compare(Conf::Database.configs(args.product,args.env),args.product)
      comparer.run
    end
  end


  namespace :package do

    # Copy DB upgrade files into sql/scripts/upgrade/:product
    task :copy_upgrade, [:product] do |t,args|
      args.with_defaults :product => Conf::Environment.product
      DBTasks.copy_db_upgrade_scripts args.product
    end

    # Copy DB installation files into sql/scripts/install/:product
    task :copy_installation, [:product, :variant] do |t,args|
      args.with_defaults :product => Conf::Environment.product
      DBTasks.copy_db_new_scripts args.product, args.variant
    end

    desc "Create standalone DB upgrade GUI for :product (default: #{Conf::Environment.product})"
    task :upgrade, [:product] => :copy_upgrade do |t,args|
      args.with_defaults :product => Conf::Environment.product
      version=Conf::Build.version(args.product)
      packager=Packager.new(args.product,TC.upgrade_dir_dest(args.product))
      packager.run_ocra "#{BASEDIR}/lib/gui/upgrade.rb", "#{args.product}_db_upgrade_#{version}.exe"
    end

    desc "Create standalone DB installation GUI for :product (default: #{Conf::Environment.product}) and optionally a variant :variant"
    task :new, [:product, :variant] => :copy_installation do |t,args|
      args.with_defaults :product => Conf::Environment.product
      version=Conf::Build.version(args.product)
      output_name="#{args.product}_db_new_#{version}"
      output_name << "_#{args.variant}" if args.variant
      output_name << ".exe"
      packager=Packager.new(args.product,TC.new_dir_dest(args.product))
      packager.run_ocra "#{BASEDIR}/lib/gui/new.rb", output_name
    end

  end

end

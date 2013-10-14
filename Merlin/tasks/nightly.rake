require 'tasklib'
require 'config/sql'
require 'config/src'
require 'config/build'
require 'config/nightly'
require 'fileutils'
require 'remote_install'
require 'db'

each_product do |product|
  
  namespace product do
    
    namespace :nightly do
      product_name = Conf::Build.product_name(product)
      root=Conf::Src.project_root(product).from_win_path
            
      task :set_nightly_flag  => "#{product}:tfs:get" do
        Conf::Build.nightly=true
        Conf::Build.timestamp = Time.now.strftime("%Y%m%d_%H%M")
        Common.logger.info "Building nightly build of '#{product_name}'"
      end

      task :copy_msi => [:set_nightly_flag, "#{product}:build:build_msi_packages"] do
        FileUtils.mkdir_p Conf::Build.nightly_destination(product)
        Conf::Nightly.output_packages(product).each do |msi|
          FileUtils.cp msi, Conf::Build.nightly_destination(product)
          Common.logger.info "Copied #{msi} to #{Conf::Build.nightly_destination(product)}"
        end
      end

      task :copy_nightly_db_scripts => [:set_nightly_flag, "#{product}:create_db_upgrade_package"] do
        upgrade_dir=File.join(Conf::Build.nightly_destination(product),"UpgrDb").to_win_path
        FileUtils.mkdir_p upgrade_dir
        Dir["#{Conf::Sql.install_dir(product).from_win_path}/*"].each do |file|
          FileUtils.cp file, upgrade_dir
        end
        Common.logger.info "Copied database upgrade files for #{product_name} to #{upgrade_dir}"
      end

      # We assume that we have a task called
      # <product>:create_db_upgrade_package for each product, defined
      # in some of the .*<product>.*.rake task files
      task :update_databases => :copy_nightly_db_scripts do
        MultiDb.upgrade(Conf::Nightly.db_configs(product), product).run
      end

      desc "Distribute nightly builds of #{product_name}"
      task :install => [:update_databases, :copy_msi] do # 
        remote_installer=RemoteInstall.new(Conf::Build.nightly_destination(product),
                                           Conf::Nightly.target_machines(product))
        remote_installer.run
        hosts=Conf::Nightly.target_machines(product).collect { |host_config| host_config.host_name }
        # Undo changes after upgrade
        TFS.undo root
        Common.logger.info "Successfully updated #{product_name} on #{hosts.join ', '}"
      end

    end
  end
end

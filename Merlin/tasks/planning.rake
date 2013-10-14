require 'tasklib'
require 'config/src'
require 'config/build'
require 'tcfileutils'
require 'rake'
require 'wsi'
  
planning_setup_version_file="#{Conf::Src.project_root('planning')}/Parameters.txt"
planning_setup_wsi_file="#{Conf::Src.project_root('planning')}/TCSetup_Client.wsi"
planning_setup_msi_file=planning_setup_wsi_file.sub(/\.wsi/,".msi")
planning_setup_ini_file=planning_setup_wsi_file.sub(/\.wsi/,".ini")
planning_setup_exe_file=planning_setup_wsi_file.sub(/\.wsi/,".exe")

planning_setup_integrations_wsi_file="#{Conf::Src.project_root('planning')}/TCSetup_Integrations.wsi"
planning_setup_integrations_msi_file=planning_setup_integrations_wsi_file.sub(/\.wsi/,".msi")
planning_setup_integrations_ini_file=planning_setup_integrations_wsi_file.sub(/\.wsi/,".ini")
planning_setup_integrations_exe_file=planning_setup_integrations_wsi_file.sub(/\.wsi/,".exe")

namespace 'planning' do
  product='planning'
  name=Conf::Build.product_name(product)
  version=Conf::Build.version(product)
  root=Conf::Src.project_root(product).from_win_path

  # Register all dll:s and ocx files in the Bin and Installation
  # directories of the project
  task :regsrv do
    glob="#{root}/{Bin,Installation}/**/*.{ocx,dll}"
    FileList[glob].each do |f|
      TC::Command.run(Conf::Command.regsrv, %Q[/s "#{f.to_win_path}"])          
    end
  end
    
  tfsco :msi_co do |tfs|
    tfs.files << planning_setup_version_file
    tfs.files << planning_setup_wsi_file
    tfs.files << planning_setup_msi_file
    tfs.files << planning_setup_ini_file
    tfs.files << planning_setup_exe_file
    tfs.recursive=false
  end 
  
  task :params_update => :msi_co do
    TCFileUtils.gsub planning_setup_version_file,/(VERSION=)(.*)/,"\\1#{version}"
  end
    
  tfsco :integration_msi_co do |tfs|
    tfs.files << planning_setup_integrations_wsi_file
    tfs.files << planning_setup_integrations_msi_file
    tfs.files << planning_setup_integrations_ini_file
    tfs.files << planning_setup_integrations_exe_file
    tfs.recursive=false
  end 
  
  namespace :build do

    desc "create MSI packages for Planning"
    task :build_msi_packages => [:msi_co, :integration_msi_co] do
      Wsi.new(planning_setup_integrations_wsi_file, name, version).run
      Wsi.new(planning_setup_wsi_file,name,version).run
    end

    task :copy_to_file_server => "build:build_msi_packages" do
      deploy_script="#{root}/Create Public Distr.bat"
      TC::Command.run_in_dir(deploy_script, version)
      Common.logger.info "Copied release package to file server using '#{deploy_script}'"
    end
    
    desc "Deploy packages for #{name}"
    task :deploy => :copy_to_file_server
    
  end


  # Inject the regsrv task as a dependency for build tasks associated
  # with vbp files
  vb6_gens=task_generators(product).select { |g| /\.vbp/ =~ g.project_file }
  Rake::Application.post_init_hooks << proc do
    vb6_gens.each { |p| inject_before(/#{p.build_task_name(p.project_file)}$/,"planning:regsrv") }
  end

end


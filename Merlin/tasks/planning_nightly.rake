require 'command'
require 'tfs'
require 'config/sql'
require 'config/src'

namespace 'planning' do
  root=Conf::Src.project_root('planning').from_win_path

  task :checkout_db_upgrade_dir => "planning:tfs:get" do
    TFS.checkout Conf::Sql.install_dir('planning')
  end

  # Task used for nightly builds, where the DB package needs to be
  # updated.
  task :create_db_upgrade_package => :checkout_db_upgrade_dir do
    db_packager = File.join root, "RunOrderCreator.exe"
    log_file="#{File.join(BASEDIR,File.basename(db_packager,'.exe')).to_win_path}.log"
    parameters = ""
    parameters << " dbUpgrade/Settings" # Only generate upgrade
                                        # scripts, no scripts for new
                                        # installations
    parameters << " -f#{Conf::Build.previous_version('planning')}"
    parameters << " -t#{Conf::Build.version('planning')}"
    parameters << %Q[ -l"#{log_file}"]
    Command.run_in_dir db_packager, parameters
    Common.logger.merge_log_from log_file, db_packager
    Common.logger.info "Created DB upgrade package for planning using #{File.basename(db_packager)}"
  end

  # Set the DB upgrade run order
  task :detect_runorder => :create_db_upgrade_package do
    runorder_file = File.join(Conf::Sql.install_dir('planning'),"RunOrder.ro")
    run_order_file_names=File.readlines(runorder_file).collect {|l| l.strip}
    Conf::Sql.set_run_order_for_product 'planning', run_order_file_names
  end

end

task 'db:upgrade' => 'planning:detect_runorder'
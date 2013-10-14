require 'psexec_runner'
require 'command'

module TC
  
  class RemoteMsiInstaller

    # +host_config+ is a Conf::Nightly::TargetMachineConfig
    def initialize(target_machine)
      @psexec_runner = PsExecRunner.new target_machine
      @target_machine = target_machine
    end

    attr_accessor :target_machine

    def get_parameters_for msi_file
      parameters = ""

      # MSI parameters valid for all products. We assume
      # that all setup MSI files contain public properties by the
      # names SERVER and DBNAME that can be used when installing from
      # the command line using msiexec
      parameters << "SERVERNAME=#{@target_machine.db_server} "
      parameters << "DBNAME=#{@target_machine.db_name} "

      # Parameters (by default given in the configuration file
      # nightly.yml), specific to the given host machine and MSI
      # package, to be used for Remote Web Service end points for
      # example.
      parameters << @target_machine.parameters_for(msi_file)
    end

    def run target_msi_file
      msi_name=File.basename(target_msi_file,".msi")
      remote_install_log_file   = File.join(File.dirname(target_msi_file), msi_name+"_install.log").to_win_path
      parameters = get_parameters_for target_msi_file
      install_command   = "msiexec /passive /qn /i #{target_msi_file} /Lcwe #{remote_install_log_file} #{parameters}"
      @psexec_runner.run install_command 
      Common.logger.info "Installed #{msi_name} on #{@target_machine.host_name}"
    end

  end

end

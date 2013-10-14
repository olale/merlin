require 'psexec_runner'

module TC
  
  class RemoteMsiUnInstaller

    # +target_machine+ is a Conf::Nightly::TargetMachineConfig
    def initialize(target_machine)
      @psexec_runner = PsExecRunner.new target_machine
      @target_machine = target_machine
    end

    attr_accessor :target_machine

    def run target_msi_file
      msi_name=File.basename(target_msi_file,".msi")
      log_file   = File.join(File.dirname(target_msi_file), 
                             msi_name+"_uninstall.log").to_win_path
      remote_command   = "msiexec /passive /qn /uninstall #{target_msi_file} /Lcwe #{log_file}"
      @psexec_runner.run remote_command
      Common.logger.info "Uninstalled #{msi_name} on #{@target_machine.host_name}"
    end

  end

end

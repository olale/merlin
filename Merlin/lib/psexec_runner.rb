require 'command'

module TC
  
  class PsExecRunner

    class TargetMachine
      attr_accessor :host, :user, :password
    end
    
    def psexec
      File.join(BINDIR,"PsTools","psexec.exe")
    end

    def initialize(target_machine)
      @target_machine = target_machine
    end

    def run command
      options=@target_machine.host
      options << " /accepteula" # Accept EULA..
      options << " -e" # Does not load the specified account's profile.
      options << " -s" # Run the remote process in the System account.
      options << " -u #{@target_machine.user}" 
      options << " -p #{@target_machine.password}"       
      Command.run psexec, %Q[#{options} #{command}]
    end

  end

end

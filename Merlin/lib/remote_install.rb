require 'remote_msi_installer'
require 'remote_msi_uninstaller'

module TC
  
  class RemoteInstall

    attr_accessor :targets
    
    # Initialize remote installation for target machines that should
    # be configured for the selected product
    def initialize(msi_dir, targets)
      @msi_dir = msi_dir.from_win_path
      @targets = targets
    end
    
    # Remotely re-install all MSI packages in @msi_dir on +targets+
    def run
      threads=[]
      targets.each do |target_machine| 
        threads << Thread.new do 
          remote_install(target_machine) 
        end
      end
      threads.each {|t| t.join }
    end

    private

    # 1. Mount the target machine's Windows/Temp folder   
    # 2. Copy msi packages from Conf::Build.destination(product) to the
    #    target machines' Windows/Temp folder
    # 3. Run psexec to install the msi package
    # 4. Unmount the remote Windows/Temp folder
    def remote_install target_machine
      mount_path = "#{target_machine.host}/c$/Windows/Temp".to_win_path
      remote_path = "c:/Windows/Temp".to_win_path
      begin
        # 1.
        if !File.exist?  mount_path
          Command.run "net", "use #{mount_path} #{target_machine.password} /user:#{target_machine.user}"
        end
        # 2.
        msi_packages=Dir["#{@msi_dir}/*.msi"]
        remote_msi_uninstaller = RemoteMsiUnInstaller.new target_machine
        remote_msi_installer = RemoteMsiInstaller.new target_machine
        msi_packages.each do |msi_file|
          msi_name=File.basename(msi_file)
          remote_msi_file=File.join(remote_path, msi_name).to_win_path
          if File.exist?(File.join(mount_path,msi_name))
            remote_msi_uninstaller.run remote_msi_file
          end
          Command.run "xcopy", %Q["#{msi_file.to_win_path}" #{mount_path} /Y /R]
          remote_msi_installer.run remote_msi_file
        end
      ensure
        # 4.
        Command.run "net", "use #{mount_path} /d"      
      end
    end

  end

end

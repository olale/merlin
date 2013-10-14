require 'config/command'
require 'uuidtools'
require 'command'
require 'common'
require 'msi'

module TC
  class Wsi

    def wfwi
      Conf::Command.wfwi
    end


    def new_uuid
      UUIDTools::UUID.random_create.to_s.upcase
    end

    attr_reader :name, :code, :wsi, :msi, :log_file, :version

    def initialize(wsi,name,version)
      @wsi=wsi.to_win_path
      @msi=wsi.gsub(/wsi/,"msi").to_win_path
      @code="{#{new_uuid}}"
      @name=name
      @version=version
      suffix=Time.now.strftime("%Y%m%d_%H%M")      
      @log_file=File.join(BASEDIR,"wfwi_#{suffix}.log").to_win_path
    end

    # Run the Symantec WSI Compiler, e.g.:
    # "C:\Program Files (x86)\Altiris\Wise\Windows Installer Editor\WfWI.exe" "TcSetup_Client.wsi"
    #  /c /s /p ProductName="Test 6.8.1" 
    # /p ProductVersion=6.8.1 
    # /p ProductCode={C57E00AE-E20E-4FB9-B329-56744FFBDA3F} 
    # /o "TcSetup_Client.msi" /l "c:\test.log" /c="MSI"
    
    def run
      options = %Q["#{wsi}" /c]
      options << %Q[ /p ProductName="#{name}"]
      options << %Q[ /p ProductVersion=#{version}]
      options << %Q[ /p ProductCode=#{code}]
      options << %Q[ /s] # silent
      options << %Q[ /o "#{msi}"]
      options << %Q[ /l "#{log_file}"]
      FileUtils.rm log_file if File.exist? log_file
      Command.run wfwi, options
      result = File.read(log_file)
      FileUtils.rm log_file
      Common.logger.debug(result,wfwi)
      # Use MsiInfo.exe to update the subject of the MSI file to be the version number
      MSI.set_subject msi, version
      Common.logger.info("Built #{msi} for '#{name}' v.#{version}")
    end

  end
end

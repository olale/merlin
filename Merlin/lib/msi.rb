require 'config/command'
require 'command'

module TC

  class MSI

    class << self
      def mssiinfo
        Conf::Command.msiinfo
      end
      
      def set_subject(file, subject)
        Command.run msiinfo, %Q["#{file}" -j "#{subject}"]
      end 
      
      def get_summary_info(msi)
        Command.run(msiinfo, %Q["#{msi}"])[:stdout]
      end 
      
    end  
  end
  
end

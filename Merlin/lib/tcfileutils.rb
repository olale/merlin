require 'tempfile'
require 'fileutils'

module TC
  module TCFileUtils
    
    # Create a new file in the current users temp-folder, with a unique random name
    # The new file will contain the text from erbTemplateFile filled with values from obj.
    def self.file_from_template(erbTemplateFile,obj)
      erb_template = ERB.new(File.open(erbTemplateFile.to_s,"r:UTF-8") {|io| io.read})
      to_tmp_file erb_template.result(obj.get_binding)
    end

    # Create a new file in the current users temp-folder, with a unique random name prefixed with "TC_"
    def self.to_tmp_file(str)
      # Use Etc.systmpdir if you want to know the path to the temp folder
      tmp_file = Tempfile.new("TC_", :encoding => "UTF-8") #Create tempfile with unique name prefixed with "TC_"
      tmp_file.write str      
      tmp_file.close
      tmp_file.path
    end

    def self.gsub(file,pattern,replacement)
      tmp_file = Tempfile.new(File.basename(file))
      File.open(file) do |f| 
        tmp_file.write f.read.gsub(pattern,replacement) 
      end
      tmp_file.close
      FileUtils.mv tmp_file.path, file, :force => true
    end

    def self.simple_name(file)
      arr=File.basename(file).split(".")
      File.file?(file) ? arr[0..-2].join(".") : arr[0]
    end
    
  end
end

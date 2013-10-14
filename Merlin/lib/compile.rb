# -*- coding: iso-8859-1 -*-
require 'command'
require 'common'
require 'tcfileutils'
require 'configuration'
require 'config/command'
require 'set'
require 'fileutils'

module TC

  include Common

  # Wrapper for the SignTool command (signtool.exe)
  class SignTool
    
    attr_accessor :key_file, :password
    
    def initialize(key_file,password)
      @key_file=key_file
      @password=password
    end

    def sign(file)
      TC::Command.run Conf::Command.signtool, %Q[/f "#{key_file}" /p #{password} "#{file}"]
    end

  end

  # Wrapper for devenv.exe (Visual Studio). This is used for creating
  # msi packages from .vdproj setup projects
  class Devenv
    
    

    attr_accessor :solution, :build_config, :setup_project, :options, :out_file

    def initialize(solution, setup_project,build_config="Release")
      @solution=solution
      @build_config=build_config
      @setup_project=setup_project
      # VS cannot handle temporay files, nor can it empty existing
      # compiler output files, so we'll have to clear the log manually
      # here..
      @out_file="devenv.out"
      FileUtils.rm @out_file if File.exist? @out_file
      # .. and it cannot create the activity log file if it doesn't
      # exist.
      @log_file="devenv.log"
      FileUtils.touch @log_file
    end

    # Extract all <tt>description</tt> elements from the log file
    # produced by devenv.exe and convert them from UTF-16LE to
    # US-ASCII where possible. Return a string with the extracted log
    # entries
    def processed_log(f,regexp)
      log = ''      
      loglines = File.open(f,'rb:UTF-16LE') do |f| 
        f.readlines.each do |l|
          begin
            l.encode!('US-ASCII')
          rescue Encoding::UndefinedConversionError
            l=""
          end
          if regexp =~ l
            log << $1+"\n"
          end
        end
      end
      log
    end

    def output
      log = ''      
      File.open(@out_file, "r:Windows-1252") do |io| 
        io.readlines.each do |l|
          begin
            l.encode!('UTF-8')
          rescue Encoding::UndefinedConversionError
            l=""
          end
          log << l
        end
      end
      log
    end

    def log
      processed_log(@log_file, /<description>(.*)<\/description>/)
    end

    def run
      begin
        TC::Command.run(Conf::Command.devenv, 
                        %Q["#{solution}" /Out "#{@out_file.to_win_path}" /Build #{build_config}  /Project "#{setup_project}" #{options}])
        Common.logger.debug(output,Conf::Command.devenv)
      rescue RuntimeError => e
        if output.include? "An error occurred while validating.  HRESULT = '8000000A'"
          Common.logger.info("Running devenv again due to previous race condition ...")
          run
        else
          raise e
        end
      end
    end
    
    def setup
      TC::Command.run Conf::Command.devenv, %Q[/Setup /Log "#{@log_file.to_win_path}" ]
      Common.logger.debug(log,Conf::Command.devenv)
    end

  end

  class SN
    

    # Detect missing certificate entries in the local certificate
    # stores by analysing the error messages from MSBuild/Devenv and
    # writing a sequence of commands to a batch file, which has to be
    # run manually by the user so the password is not provided by a
    # script
    def self.detect_missing(product=Conf::Environment.product)
      certificate_pattern =  /Cannot import the following key file: (.*\.pfx)\./
      csp_target_pattern = %r{key container name: (VS_KEY_.*)$}
      str = ""
      # Find a message in the build log saying the certificate is not installed
      File.open(Conf::Src.msbuild_log) {|f| str = f.read }
      cert = certificate_pattern.match(str)[1] if csp_target_pattern =~ str
      batch_file='sn.bat'
      # Find a certificate file
      pattern="#{Conf::Src.project_root(product)}/**/#{cert}".gsub(/\\/,"/")
      f = Dir.glob(pattern)[0]
      containers = Set.new
      str.scan(csp_target_pattern) { |match| containers << match[0] }
      sn_commands = containers.collect { |c| %Q["#{Command}" -i "#{f}" #{c}].gsub(%r{/},"\\") }
      File.open(batch_file,'w') {|f| f.write sn_commands.join("\r\n") }
      Common.logger.info "Done. Run #{batch_file} to install all missing keys."
    end

    def self.list_settings
      TC::Command.run Conf::Command.sn,"-Vl"
    end

    def self.create_public_key(infile,outfile)
      infile.gsub!(%r{/},"\\")
      outfile.gsub!(%r{/},"\\")
      TC::Command.run Conf::Command.sn,%Q[-p "#{infile}" "#{outfile}"]
    end

  end  


end

require 'config/command'
require 'config/src'

Albacore.configure do |config|

  config.msbuild do |msb|
    msb.targets = [:clean, :build]
    msb.properties = { :configuration => :Release, :TrackFileAccess => :false }
    msb.parameters = ["/l:FileLogger,Microsoft.Build;logfile=#{TC::Conf::Src.msbuild_log}"]
  end

  config.mstest do |mst|    
    # mst.command=TC::Conf::Command.mstest_command
    # For more detail options, see http://msdn.microsoft.com/en-us/library/ms182489(v=vs.80).aspx
    # Encoded as symbols here
    details=[:stderr, :stdout, :errormessage, :testname]
    mst.parameters=details.collect {|d| "/detail:#{d}"}
  end

  config.assemblyinfo do |asm|
    asm.company_name = "Foo AB"
    asm.copyright = "Foo AB #{Time.now.year}"
  end

end

class AssemblyInfo

  def build_header
    @lang_engine.class.instance_methods(false).include?(:before) ? [@lang_engine.before()] : []
  end

  def build_footer
    @lang_engine.class.instance_methods(false).include?(:after) ? [@lang_engine.after()] : []
  end

end

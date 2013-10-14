require 'configuration'

class CommandNotFoundError < RuntimeError; end

class TC::Conf::Command < TC::Conf::YamlConf
  
  def initialize
    @paths={}
  end
  
  # Load the correct path by finding the file through lookup via 
  # the glob available as the value in the configuration hash we 
  # access by the method name
  def method_missing(method,*args)
    if @paths.has_key? method
      @paths[method]
    else
      glob=self[method.to_s]
      paths=Dir[glob]
      msg = "Configuration error in config/#{self.class.simple_name}.yml: "+
        "No such command '#{method}' found by pattern #{glob}"
      raise CommandNotFoundError.new(msg) unless paths && paths.any?
      @paths[method] = paths.first      
    end
  end
  
end

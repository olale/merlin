require 'psych'
require 'support'

module TC 

  module Conf
    
    # Domain Specific Language (DSL) class for configuration files, where configuration files
    # correspond to a class. Class methods are looked up through a
    # singleton instance (__instance__), and instance method names are
    # mapped to configuration keys in the corresponding configuration
    # file, unless explicit methods are provided. By looking up all
    # class methods from singleton instances, we can also have a
    # number of configuration instances (database configurations) that
    # are all instances of a subclass of YamlConf and all share the
    # same language without separate configuration.
    class YamlConf

      def conf
        @conf ||= load(self.class.simple_name+".yml")
      end

      def reset!
        @conf=nil
      end

      def [](key)
        conf[key]
      end
      
      # Look up keys in the configuration hash, or set configuration
      # values in the hash if using 'setter' methods (with a "=" suffix)
      def method_missing(method,*args)
        method_name=method.to_s
        if method_name.end_with? "="
          method_name=method_name[0..-2]
          conf[method_name]=args[0]
        else
          self[method_name]
        end
      end

      def save!
        File.open(@path, "w") do |io|
          Psych.dump conf, io
          Common.logger.info "updated config file at #@path"
        end
      end


      # Loads a Yaml configuration file, either by absolute path
      # reference or by reference to a configuration file in +CONFDIR+
      # (+BASEDIR+/config)
      def load(f)
        @path="#{CONFDIR}/#{f}"
        raise "No file #{f} in #{CONFDIR}, copy #{f}.sample to #{f}" unless File.exist? @path
        Psych.load_file @path 
      end

      class << self
        
        def __instance__
          @instance ||= new
        end

        def method_missing(method,*args)        
          __instance__.send method,*args
        end

      end
    end
    
  end
end

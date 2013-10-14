require 'configuration'

module TC

  class Conf::Logging < Conf::YamlConf 
    
    class LogPattern
      attr_accessor :pattern, :replacement, :command
      
      def initialize
        @command=/.*/i
      end

      def ignore?
        level.nil?
      end

      def level=(str)
        @level=TC::Conf::Logging.level(str)
      end
      
      def level
        @level
      end

    end

    LOG_FILE=File.join(BASEDIR,"tc.log")

    class << self

      def log_patterns
        @log_patterns ||= (self['log_patterns'] || []).collect do |h|
          l = LogPattern.new
          l.pattern = h['pattern']
          l.replacement = h['replacement'] if h.has_key? 'replacement'
          l.level = h['level'] if h.has_key? 'level'
          l.command = /#{h['command'].downcase}/i if h.has_key? 'command'
          l
        end
      end

      def file
        LOG_FILE
      end      

      def shift_age
        self['shift_age'] || 0
      end
      
      def shift_size
        self['shift_size'] || 1048576
      end
      
      def level(l=log_level)
        case l
        when 'debug'
          Logger::DEBUG
        when 'info'
          Logger::INFO
        when 'warn'
          Logger::WARN
        when 'error'
          Logger::ERROR
        when 'fatal'
          Logger::FATAL
        else
          nil
        end
      end

    end

  end

end

require 'filtered_logger'
require 'config/logging'
require 'support'

module TC
  module Common    
    
    def self.logger
       @logger ||= FilteredLogger.new(Conf::Logging)
    end
    
    def self.reset_logger
      Conf::Logging.reset!
       @logger = FilteredLogger.new(Conf::Logging)
    end
    
  end
end


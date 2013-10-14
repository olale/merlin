require 'logger'
require 'config/build'
require 'set'

module TC
  
  class FilteredLogger

    class MultiIO
      def initialize(*targets)
        @targets = targets
      end

      def write(*args)
        @targets.each {|t| t.write(*args)}
      end

      def close
        @targets.each(&:close)
      end

      def flush
        @targets.each(&:flush)
      end
    end
    attr_accessor :config, :logger, :log_file

    # This logger modifies the log output according to the logging
    # configuration hash param: +config+: parsed from
    # config/logging.yml
    def initialize(config)
      @config=config
      file=File.open(Conf::Logging::LOG_FILE, "w")
      @log_file=MultiIO.new(STDOUT, file)
      @logger= init_logger
    end

    def level=(level)
      @logger.level=level
    end

    def level
      @logger.level
    end

    def init_logger
      l = Logger.new(@log_file)
      l.datetime_format = "%Y-%m-%d %H:%M"
      l.formatter = proc do |severity, datetime, progname, msg|
        "#{severity} [#{datetime}]: #{msg}\n"
      end
      l.level = config.level
      l
    end

    def log_patterns
      config.log_patterns
    end

    def command_string(command,options)
      "#{File.basename(command)} #{options}".encode("UTF-8")
    end

    def log_prefix(command,options)
      %Q[\n\n    Command: "#{command_string(command,options)}"\n\n    Message: ].encode("UTF-8")
    end
    
    def format_message(msg)
      msg.gsub(/\n/,"\n             ")
    end

    def log_running(command,options)
      debug(log_prefix(command,options)+" running ...",File.basename(command))
    end

    def get_prefix command,options,stream
      log_prefix(command,options)+format_message(stream).encode("UTF-8")
    end

    def log_run(command,options,stderr,stdout,status)
      msg = get_prefix command,options,stderr
      cmd_name=File.basename(command)
      error(msg,cmd_name) unless stderr.empty?
      if !stdout.empty?
        msg = get_prefix command,options,stdout
        if status && status.exitstatus == 0
          debug(msg,cmd_name)
        else
          error(msg,cmd_name)
        end 
      end
    end

    # Filter all messages, so a custom error level can be set, 
    # messages can be ignored and messages may be re-written
    def filter(level,msg,cmd="")
      matched_patterns = log_patterns.select do |p| 
        p.pattern =~ msg && (p.command.nil? || (p.command =~ cmd)) 
      end
      matched_patterns.each do |p|
        if p.ignore?
          msg = msg.gsub p.pattern, ""
        else
          l = p.level || level
          logs = Set.new
          msg.scan p.pattern do |_|
            m=Regexp.last_match(0)
            logs << (p.replacement ? m.sub(p.pattern,p.replacement) : m).strip
          end          
          log_msg = logs.to_a.join("\n")
          
          log(l,log_msg) unless log_msg.empty?
        end
      end

      # Only log the original message if no log patterns match and the message is non-empty
      if !matched_patterns.any?
        log(level,msg)
      end
    end

    def merge_log_from(file, cmd)
      if File.exist? file
        log_string=File.read file
        debug log_string, cmd
        FileUtils.rm file
      else
        debug "No log file given from #{cmd}"
      end
    end

    def log(level,msg)
      logger.add(level,msg)
      if level > Logger::WARN
        # Flush the log file on error, to enable sending of log data 
        @log_file.flush
      end
      if level == Logger::ERROR && Conf::Build.abort_on_error
        raise "Conf::Build.abort_on_error=true, aborting..."
      elsif level == Logger::FATAL
        raise "Fatal error, aborting..."
      end      
    end
    
    def debug(msg,cmd=nil)
      filter(Logger::DEBUG,msg,cmd)
    end

    def info(msg,cmd=nil)
      filter(Logger::INFO,msg,cmd)
    end

    def warn(msg,cmd=nil)
      filter(Logger::WARN,msg,cmd)
    end

    def error(msg,cmd=nil)
      filter(Logger::ERROR,msg,cmd)
    end

    def fatal(msg,cmd=nil)
      filter(Logger::FATAL,msg,cmd)
    end

  end
end

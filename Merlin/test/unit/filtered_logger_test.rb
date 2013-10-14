# -*- coding: utf-8 -*-
require 'compile'
require 'config/logging'
require 'logger'
require 'test_base'
require 'fileutils'
require 'ostruct'

class FilteredLoggerTest < TestBase

  attr_reader :log_file

  def cwd
    File.dirname(__FILE__)
  end

  def setup_logger
    conf = OpenStruct.new
    conf.file="config_file"
    conf.shift_age=1
    conf.level=Logger::INFO
    p = Conf::Logging::LogPattern.new
    p.pattern=/a/i
    p.replacement="b"
    p.level='info'
    p.command=/tf.exe/i
    conf.log_patterns=[p]
    logger=FilteredLogger.new conf
    def logger.log(level,msg)
      @log = {:level => level, :msg => msg}
    end
    def logger.logs
      @log
    end
    logger
  end

  def setup
    log_file_name="test.log"
    @old_log_file=Common.logger.log_file
    @log_file = Common.logger.log_file=File.join(cwd,log_file_name)
    Dir["#{cwd}#{log_file_name}*"].each do |f|
      TFS.checkout f
    end
    FileUtils.rm_rf @log_file if File.exist? @log_file
    Common.logger.log_file = @log_file
  end
  
  def teardown
    Dir["#{cwd}#{File.basename(log_file)}*"].each do |f|
      FileUtils.rm_f f
    end
    Common.logger.log_file=@old_log_file
  end

  def test_log_prefix
    cmd="cmd"
    cmd_string="/some/path/to/"+cmd
    options = "/a /b"
    log_prefix=Common.logger.log_prefix(cmd_string,options)
    refute_operator log_prefix, :include?, cmd_string
    assert_operator log_prefix, :include?, cmd
    assert_operator log_prefix, :include?, options
  end

  def test_format_message
    msg="MESSAGE"
    assert_equal msg, setup_logger.format_message(msg).strip
  end

  def test_devenv_log_filter
    devenv = Devenv.new(nil,nil)
    devenv.out_file = File.join(File.dirname(__FILE__),"devenv.txt")    
    logger=setup_logger
    def logger.log_patterns
      p = Conf::Logging::LogPattern.new
      p.pattern=/WARNING: (.*)/
      p.level='warn'
      p.command=/devenv.exe/i
      [p]
    end
    logger.info(devenv.output,Devenv::Command)
    refute_nil logger.logs
    assert_match /(warning.*){3}/im, logger.logs[:msg], "there should be 3 merged warnings in the compilation log"
  end

  def test_filter
    logger=setup_logger
    logger.filter(Logger::ERROR, 
                  "this is an info message", 
                  %Q["/path/to/tf.exe" foo])
    assert_equal Logger::INFO, logger.logs[:level]
  end

end

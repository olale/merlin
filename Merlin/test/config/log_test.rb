require 'test_base'
require 'config/logging'
require 'logger'

class LogTest < TestBase

  def valid_log_levels
    ['debug', 'info', 'warn', 'error', 'fatal']
  end

  def test_log_settings
    l=Conf::Logging.log_level
    assert valid_log_levels.include?(l), "invalid log level #{l}"
  end

  def test_log_pattern_format
    assert (Conf::Logging.log_patterns.class == Array)
  end


end

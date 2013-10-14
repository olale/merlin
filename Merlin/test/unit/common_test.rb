require 'common'
require 'test_base'

class CommonTest < TestBase

  def test_logger_not_nil
    refute_nil Common.logger
  end

  def test_logger_filtered_logger
    assert_kind_of FilteredLogger, Common.logger
  end

end

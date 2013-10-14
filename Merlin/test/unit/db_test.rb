require 'db'
require 'test_base'

class DbTest < TestBase

  def test_compare_command_exists
    assert File.exist?(OCDBCompare::OCDB)
  end

end

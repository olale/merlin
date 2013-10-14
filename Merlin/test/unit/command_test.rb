require 'command'
require 'config/command'
require 'test_base'

class CommandTest < TestBase

  def test_status_ok
    assert Command.status_ok?(Conf::Command.tf,%Q[status "#{TESTDIR}"])
  end

end

require 'config/command'

class CommandConfigTest < TestBase

  def verify_path(command)
    begin
      cmd=Conf::Command.send command
    rescue CommandNotFoundError => e
      flunk "#{Conf::Command[command]} should be a valid path"
    end
  end

  def test_sqlcommand
    verify_path 'sqlcommand'
  end

  def test_devenv
    verify_path 'devenv'
  end

  def test_tf
    verify_path 'tf'
  end


end

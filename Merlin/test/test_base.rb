require 'minitest/autorun'
require 'common'

class TestBase < MiniTest::Test
  include TC
  include Common
  
  def product
    Conf::Environment.product
  end

  def env
    Conf::Environment::Settings::TEST    
  end

  def products
    Conf::Environment.products
  end

end

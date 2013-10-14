require 'config/build'
require 'test_base'

class BuildTest < TestBase

  def test_version_format
    assert_match(/\d+\.\d+\.\d+/,Conf::Build.version)
  end

  def test_previous_version
    products.each do |product|
      assert_operator(Conf::Build.previous_version(product), 
                      :<, 
                      Conf::Build.version(product), "The previous version should be less than the current version for #{product}")
    end
  end

  def test_next_version
    products.each do |product|
      assert_operator(Conf::Build.next_version(product), 
                      :>, 
                      Conf::Build.version(product), "The next version should be greater than the current version for #{product}")
    end
  end

  def test_product_name
    refute_nil Conf::Build.product_name
  end

end

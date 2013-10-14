require 'config/environment'

class EnvironmentTest < TestBase

  def test_modifying_env
    old_product=Conf::Environment.product
    # Pick another product
    new_product=(Conf::Environment.all_products-[old_product])[0]
    Conf::Environment.product=new_product
    refute_equal old_product, Conf::Environment.product
  end

end

# -*- coding: utf-8 -*-
require 'test_base'
require 'support'

class Foo; end

module Bar
  class Baz; end
end

class SupportTest < TestBase

  def test_class_simple_name
    assert(Foo.simple_name == 'foo')
    assert (Bar::Baz.simple_name == 'baz')
  end

  def test_local_address
    assert 'localhost'.local_address?
  end

  def test_conversion
    assert_equal "\\å\\ä\\ö".encode("Windows-1252"), "/å/ä/ö".to_win_path
  end

  def test_version_gte
    assert_operator "4.2.3040", :version_gte, "04.2.3040"
    assert_operator "04.3.0002", :version_gte, "4.2.3040"
    assert_operator "13.0.0002", :version_gte, "4.2.3040"
    refute_operator "4.2.3039", :version_gte, "4.2.3040"
    refute_operator "3.3.3040", :version_gte, "4.2.3040"
  end

  def test_version_gt
    refute_operator "4.2.3040", :version_gt, "4.2.3040"
    assert_operator "4.3.0002", :version_gt, "4.2.3040"
    assert_operator "13.0.0002", :version_gt, "4.2.3040"
    refute_operator "4.2.3039", :version_gt, "4.2.3040"
    refute_operator "3.3.3040", :version_gt, "4.2.3040"
  end

end

# -*- coding: utf-8 -*-
require 'test_base'
require 'tcfileutils'

class TCFileUtilsTest < TestBase

  def setup
    @str="åäö"
  end

  def test_simple_name
    p="Kalle"
    name=TCFileUtils.simple_name("/path/to/a/project/called/#{p}.vbproj")
    assert_equal p, name
  end

  def test_template_encoding
    template=File.join(File.dirname(__FILE__),"template_test.erb")
    erb_template = ERB.new(File.open(template,"r:UTF-8") {|io| io.read})
    string_from_template=erb_template.result @str.get_binding
    assert_equal @str,string_from_template
  end

  def test_temp_file_encoding
      tmp_file = Tempfile.new(File.basename("TC_"))
      tmp_file.write(@str)
      tmp_file.close
      assert_equal @str, File.open(tmp_file.path,"r:UTF-8") {|io| io.read}
  end


end

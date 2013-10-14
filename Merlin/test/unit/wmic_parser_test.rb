require 'wmic_parser'
require 'test_base'

class WmicParserTest < TestBase

  def setup
    lines=[]
    File.open(File.join(File.dirname(__FILE__),"files","products.txt"),mode: "rb:utf-16le") do |f|
      lines=f.readlines
    end
    @wmic_parser=WmicParser.new(lines)
  end


end

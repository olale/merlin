require 'tcfileutils'
require 'ostruct'

class FileManipulationTest < TestBase

  def test_tmp_file_creation
    template = Pathname.new(TC::SQLDIR)+"restore.sql.erb"
    obj = OpenStruct.new
    obj.db = "Test2"
    obj.bak_file = "test.bak"
    tmp_file = TC::TCFileUtils.file_from_template(template,obj)
    assert File.exists?(tmp_file)
    File.open(tmp_file) do |f| 
      str = f.read
      db_pattern = /#{Regexp.quote(obj.db)}/
      bak_pattern = /#{Regexp.quote(obj.bak_file)}/
      
      assert(db_pattern =~ str)
      assert(bak_pattern =~ str)
    end
  end

  
end

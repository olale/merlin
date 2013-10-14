require 'test_base'
require 'db'

class RestoreTest < TestBase

  def test_sql_dir_exists
    assert(SQLDIR!=nil, "there should be a valid SQLDIR constant")
  end

end

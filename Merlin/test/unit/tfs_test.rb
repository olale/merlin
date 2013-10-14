require 'tfs'
require 'test_base'

class TFSTest < TestBase

  attr_reader :tfs

  def setup
    @tfs = TFS
  end

  def test_commands_available
    assert_respond_to tfs, :status
    assert_respond_to tfs, :get
    assert_respond_to tfs, :checkin
    assert_respond_to tfs, :checkout
    assert_respond_to tfs, :undo_unmodified
  end

end

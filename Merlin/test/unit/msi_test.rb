require 'msi'
require 'tfs'
require 'test_base'

class MSITest < TestBase

  def setup
    file_dir=File.join(File.dirname(__FILE__),"files")
    msi_file="TcWeb42Setup.msi"
    @orig_msi=File.join(file_dir,msi_file)
    TFS.checkout @orig_msi
    @tmp_dir=File.join(file_dir,"tmp")
    FileUtils.mkdir_p @tmp_dir
    tmp_msi=File.join(@tmp_dir,msi_file)
    FileUtils.cp @orig_msi,tmp_msi    
    @msi=tmp_msi
  end

  def teardown
    FileUtils.rm_rf @tmp_dir
    TFS.undo @orig_msi
  end

  def test_set_version
    version="5.2.3"
    MSI.set_subject @msi, version    
    assert_operator /#{version}/, :=~, MSI.get_summary_info(@msi)
  end

end

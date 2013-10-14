require 'projects/vs'
require 'test_base'
require 'tfs'

class VDProjTest < TestBase

  attr_reader :project, :vdproj_file

  def setup
    file_dir=File.join(File.dirname(__FILE__),"files")
    TFS.checkout(file_dir) unless File.writable?(file_dir )
    @tmp_dir=File.join(file_dir,"tmp")
    @vdproj_file=File.join(@tmp_dir,"TcWeb42Setup.vdproj")
    FileUtils.mkdir @tmp_dir unless File.exist? @tmp_dir
    FileUtils.cp File.join(file_dir,"TcWeb42Setup.vdproj"),@vdproj_file
    @project = VDProj.new(@vdproj_file)
  end

  def teardown
   FileUtils.rm_rf @tmp_dir
  end

  def test_set_version
    old_version=project.version
    major,minor,revision=old_version.split(".").collect {|s| s.to_i }
    new_version=[major,minor,revision+1].join(".")
    project.version=new_version
    new_revision=project.version.split(".")[-1].to_i
    assert_equal revision+1,new_revision
  end

  def test_set_product_code
    new_code="{123}"
    project.product_code=new_code
    assert_equal new_code,project.product_code
  end

end

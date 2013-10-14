require 'projects/vs'
require 'test_base'
require 'tfs'

class VSTest < TestBase

  attr_reader :project, :project_file

  def setup
    setup_vsproject
    setup_vssolution
  end

  def setup_vsproject
    file_dir=File.join(File.dirname(__FILE__),"files")
    @tmp_dir=File.join(file_dir,"tmp")
    @project_file=File.join(@tmp_dir,"Test.csproj")
    FileUtils.mkdir @tmp_dir unless File.exist? @tmp_dir
    FileUtils.cp File.join(file_dir,"Test.csproj"),@project_file
    @project = VSProject.new(@project_file)
  end

  def setup_vssolution
    file_dir=File.join(File.dirname(__FILE__),"files", "planning")
    @sln_file=File.join(file_dir,"All.sln")
    @sln = VSSolution.new(@sln_file)
  end

  def teardown
   FileUtils.rm_rf @tmp_dir
  end

  def test_mstest
    assert @project.mstest?, "'files/Test.csproj' should be recognized as a MSTest project"
  end

  def test_output_path_valid
    assert_equal File.join(@tmp_dir,"bin","Release"), @project.absolute_output_path.sub(%r{\\$},'')
  end

  def test_solution_contains_virtual_projects
    virtual_projects_included=@sln.projects.any? {|project| project.class == VirtualProject }
    assert virtual_projects_included, "there should be a virtual project among the projects in the solution"
  end

  def test_solution_projects_contain_assemblyinfo
    asm_included=@sln.projects.all? {|project| project.asm_file }
    assert asm_included, "there should be a AssemblyInfo files in all projects in the solution"
  end

end

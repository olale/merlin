require 'test_base'
require 'tfs'
require 'config/src'
require 'config/command'
require 'tasklib'

class SrcConfigTest < TestBase

  def test_src_local_root
    products.each do |product|
      assert(File.exists?(Conf::Src.project_root(product)), 
             "there should be a local directory mapped for #{product} as configured in src.yml")
    end
  end

  def test_src_tf_command
    command = Conf::Command.tf
    assert(File.exists?(command),
           "config/src.yml[tf]: #{command} is required for source code management")
    `"#{command}" help`
    assert($? == 0, "#{command} should execute without problems")
  end

  def test_src_tfpt_command
    command = Conf::Command.tfpt
    assert(File.exists?(command),
           "config/src.yml[tf]: #{command} is required for source code management")
    `"#{command}" help`    
    assert($? == 0, "#{command} should execute without problems")
  end

  def test_tfs_server_settings
    products.each do |product|
      project_root=Conf::Src.project_root(product)
      result = TFS.status(project_root)
      assert(result[:status].exitstatus == 0, 
             "#{project_root} should be under source control.")
    end
  end

  def test_project_files_exist
    products.each do |product|
      project_files=Conf::Src.project_files(product)
      project_files.each do |project_file|
        result = TFS.status(project_file)
        assert(result[:status] && (result[:status].exitstatus == 0), 
               "Project file #{project_file} derived from config/src.yml should exist in source control.")
        end
    end
  end

  def test_output_files_exist
    products.each do |product|
      output_paths=Conf::Src.output_files(product)
      refute_empty output_paths
    end
  end

  def test_targets
    products.each do |product|
      msbuild_project_info_collection=Conf::Src.project_info_collection(product)
      msbuild_project_info_collection.each do |info|
        if MSBuildTaskGenerator.project_file_pattern =~ info[:file]
          refute_nil(info[:target], 
                     "there should be a build target configured for MSBuild project #{info[:file]}")
        end
      end
    end
  end

  def test_sub_project_files_exist
    products.each do |product|
      project_files=Conf::Src.project_files(product)
      project_files.each do |project_file|
        if project_file.end_with? "sln"
          assert File.exists?(project_file), "#{project_file} must exist"
          sln = VSSolution.new project_file
          sub_projects = sln.projects
          assert sub_projects.any?, "there should be projects in #{project_file}"
          sub_projects.each do |s|
            assert File.exists?(s.project_file), "#{s.project_file} must exist"
          end
        end
      end
    end
  end

end

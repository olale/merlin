require 'test_base'
require 'tasklib'
require 'rake'
require 'albacore'

class TaskLibTest < TestBase

  def setup

  end

  def task_generators(cls,&block)
    Conf::Environment.products.each do |p|
      Conf::Src.project_info_collection(p.to_s)
        .select {|project_info| cls.project_file_pattern =~ project_info[:file] }.each do |project_info|
        yield cls.new(project_info,p)
      end
    end    

  end

  def msbuild_task_generators(&block)
    task_generators MSBuildTaskGenerator,&block
  end

  def vb6_task_generators(&block)
    task_generators VBPTaskGenerator,&block
  end

  def build_tasks
    msbuild_task_generators do |task_gen|
      task_names = task_gen.build_tasks
      yield task_gen.solution_file,Rake::Task[task_names[0]]
    end
  end

  def test_build_tasks_depend_on_asm_tasks
    build_tasks do |sln_file,task|
      if /\.sln/ =~ sln_file
        asm_tasks = task.prerequisites.any? { |t| t.end_with? "updateAssemblyInfo" }
        assert asm_tasks, "#{task.name} should depend on 'asm' tasks but only depends on #{task.prerequisites}"
      end
    end
  end

  def test_pool_does_not_contain_vb6_tasks
    pool=Conf::Environment::Products::POOL.to_s
    assert_empty Conf::Src.project_files(pool)
      .select {|f| VBPTaskGenerator.project_file_pattern =~f }
  end

end

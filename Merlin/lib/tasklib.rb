# -*- coding: iso-8859-1 -*-
require 'albacore'
require 'pathname'
require 'albacore/support/logging'
require 'command'
# require 'win32/file'
require 'rake'
require 'tcfileutils'
require 'projects/vs'
require 'projects/vb6'
require 'uuidtools'
require 'common'
require 'config/src'
require 'rake/hooks'

# Redefine Albacore Logging module to use FilteredLogger
module Logging
  def initialize
    @logger = TC::Common.logger
    super()
  end
end

# Redefine Albacore::RunCommand#run_command to use TC::Command#run
module Albacore
  module RunCommand
    def run_command(name="Command Line", parameters=nil)
      begin
        params = []
        params << parameters unless parameters.nil?
        params << @parameters unless (@parameters.nil? || !@parameters.any?)

        executable = @command
        unless command.nil?
          executable = File.expand_path(@command) if File.exists?(@command)
        end
        Dir.chdir(@working_directory) do
          TC::Command.run(executable,params.join(" "))
        end
      rescue Exception => e
        TC::Common.logger.fatal "Error while running '#{name}': #{e}"
        raise
      end
    end
  end
end

def tfsco(*args)
  args ||= []
  
  config = Struct.new(:files, :recursive).new
  config.files=[]
  config.recursive=true
  yield(config)
  
  body = proc {
    TFSCoTask.new.execute(config.files, 
                          config.recursive)
  }
  
  Rake::Task.define_task(*args, &body)

end

class TFSCoTask

  def execute(files, recursive)
    options = "/recursive" if recursive
    files.each do |file|
      if !file.nil? && 
          File.exists?(file) && 
          (File.readonly?(file) || File.directory?(file))
        TFS.checkout file, options
      end
    end
  end

end

def build_setup_project(*args)
  args ||= []
  
  config = Struct.new(:solution, :project_file, :product_version).new
  yield(config)
  
  body = proc {
    BuildSetupProjectTask.new.execute(config.solution, 
                               config.project_file, 
                               config.product_version)
  }
  
  Rake::Task.define_task(*args, &body)
end

class BuildSetupProjectTask

  def execute(solution, project_file, product_version)
    raise "unrecognized setup type #{project_file}" unless SetupProjectBuilder.setup_project? project_file
    SetupProjectBuilder.create(solution, project_file, product_version).run
  end

end

class SetupProjectBuilder

  class << self

    def setup_classes
      @setup_classes ||= []
    end

    def inherited(sub_class)
      setup_classes << sub_class
    end

    def setup_project?(project_file)
      !setup_class(project_file).nil?
    end

    def setup_class(project_file)
      setup_classes.find {|c| c.project_file_pattern =~ project_file }
    end

    def outputs(project_file)
      setup_class(project_file).new.tap {|c| c.project_file=project_file }.outputs
    end

    def create(solution, project_file, product_version)
      setup_class(project_file).new.tap do |c|
        c.solution=solution
        c.project_file=project_file
        c.product_version=product_version
      end
    end

  end

  attr_accessor :solution, :project_file, :product_version

  def new_uuid
    "{#{UUIDTools::UUID.random_create.to_s.upcase}}"
  end

  def outputs
    raise "unimplemented method 'outputs' in #{self.class}"
  end

  def run    
    raise "unimplemented method 'run' in #{self.class}"
  end

end

class VDProjBuilder < SetupProjectBuilder

  def self.project_file_pattern
    /\.vdproj$/
  end

  def outputs
    vdproj.outputs
  end

  def run    
    prepare_vdproj
    devenv = TC::Devenv.new solution.to_win_path, project_file.to_win_path
    devenv.run
  end

  private

  def vdproj
    @vdproj ||= VDProj.new(project_file)
  end

  def prepare_vdproj
    vdproj.version=product_version
    vdproj.subject=product_version
    vdproj.product_code=new_uuid
    vdproj.package_code=new_uuid
  end

end

# Stub for a class to build WiX setup projects, implement outputs and run
class WiXBuilder < SetupProjectBuilder

  def self.project_file_pattern
    /\.wsi$/
  end

end

module TC

  class NoGeneratorFoundException < RuntimeError; end

  class TaskGenerator

    include ::Rake
    include ::Rake::DSL

    attr_reader :product, :project_file, :tag

    class << self
      def generator_classes
        @generator_classes ||= []
      end

      def inherited(sub_class)
        generator_classes << sub_class
      end

      def all_project_files(product)
        Conf::Src.project_info_collection(product.to_s)
      end

      def create(product)
        all_project_files(product).collect do |project_info|
          generator_class = generator_classes.find { |c| c.project_file_pattern =~ project_info[:file] }
          raise NoGeneratorFoundException, 
          "Cannot build project file #{project_file}."+
            " Extend TaskGenerator to implement a new generator that "+
            "matches the file type" unless generator_class
          generator_class.new(project_info,product)
        end
      end
    end

    def initialize(project_info,product)
      @product=product.to_s
      raise "Illegal arg #{project_info}" unless project_info.class == Hash
      @project_file=project_info[:file]
      @tag=project_info[:tag]
      @target = project_info[:target]
    end

    def build_co_name
      "#{product}:build:co"
    end

    def create_name(file,suffix)
      "#{product}:#{TCFileUtils.simple_name(file)}:#{suffix}"
    end

    def tfs_co_task_name(file)
      create_name file, "checkout"
    end

    def build_task_name(file)
      create_name file, "build"
    end

    def version_task_name(file)
      create_name file, "version"
    end

    def build_msi_task_name(file)
      create_name file, "build_msi"
    end    

    def build_tasks
      @build_tasks ||= generate_build_tasks
    end

    def build_msi_tasks
      @build_msi_tasks ||= generate_build_msi_tasks
    end

    def generate_test_tasks
      []
    end

    def test_tasks
      @test_tasks ||= generate_test_tasks
    end
    
  end

  class MSBuildTaskGenerator < TaskGenerator
    
    alias_method :solution_file, :project_file

    attr_reader :solution

    def self.project_file_pattern
      /\.sln$/i
    end

    def self.language(file_name)
      file_name.end_with?("cs") ? "C#" : "VB.Net"
    end

    def initialize(project_info,product)
      super
      @solution = VSSolution.new solution_file
    end    

    def asm_task_name(file)
      create_name file, "updateAssemblyInfo"
    end

    def clean_task_name(file)
      create_name file, "clean"
    end

    def test_task_name(file)
      create_name file, "test"
    end

    def projects_with_asm
      solution.projects.select {|p| p.asm_file }
    end

    def asm_tasks
      projects_with_asm.collect do |project|
        assemblyinfo_file = project.asm_file        
        project_file=project.project_file
        version=Conf::Build.version(product)+".0" # Hack to introduce an extra build digit..
        assemblyinfo asm_task_name(project_file) => tfs_co_task_name(solution_file) do |asm|
          asm.version = version
          asm.file_version = version
          asm.product_name = Conf::Build.product_name(product)
          asm.output_file = assemblyinfo_file.to_win_path
          asm.language = MSBuildTaskGenerator.language assemblyinfo_file
          asm.description = Conf::Build.description(product)
        end
        asm_task_name(project_file)
      end
    end

    def setup_solution_tasks(build_deps)
      project_files = solution.project_files
      setup_project_files = project_files.select {|f| SetupProjectBuilder.setup_project? f }      
      setup_project_files.collect do |project_file|
        tfsco tfs_co_task_name(project_file) => :checkout do |tfs|
          tfs.files << project_file
          tfs.files += SetupProjectBuilder.outputs(project_file)
        end

        build_setup_project build_msi_task_name(project_file) => build_deps+[tfs_co_task_name(project_file)] do |setup|    
          setup.solution = solution_file
          setup.project_file = project_file
          setup.product_version = Conf::Build.version(product)
        end
        
        build_msi_task_name(project_file)
      end            
    end
    
    def generate_build_tasks
      tfsco tfs_co_task_name(solution_file) => :checkout do |tfs|
        tfs.files = projects_with_asm.collect { |p| p.asm_file }
        tfs.files += solution.vs_projects.collect {|p| p.absolute_output_path }
      end

      build_deps = [tfs_co_task_name(solution_file)] + asm_tasks      

      msbuild build_task_name(solution_file) =>  build_deps do |msb|
        msb.solution = solution_file
        msb.properties[:target] = @target
      end
      
      [build_task_name(solution_file)]
    end

    def generate_build_msi_tasks
      setup_solution_tasks [build_task_name(solution_file)]
    end

    def generate_test_tasks build_deps
      test_assemblies = solution.vs_projects.select { |p| p.mstest? }.collect { |p| p.output_name }
      if test_assemblies.any?
        mstest test_task_name(solution_file) => build_deps do |t|    
          t.assemblies = test_assemblies
        end
      else
        task test_task_name(solution_file) do
          TC::Common.logger.info "No MSTest test projects found in #{solution_file}"
        end
      end
      [test_task_name(solution_file)]
    end

    def test_tasks
      @test_tasks ||= generate_test_tasks [build_task_name(solution_file)]
    end

  end

  class VBPTaskGenerator < TaskGenerator

    alias_method :vbp_file, :project_file

    def self.project_file_pattern
      /\.vbp$/i
    end

    def project
      @project ||= VB6Project.new(vbp_file,Conf::Src.project_root(product))      
    end

    # Build VB6 projects
    def generate_build_tasks      
      name=build_task_name(vbp_file)
      # Check out the project file
      tfsco tfs_co_task_name(vbp_file) => :checkout do |tfs|
        projects= []
        project.recursively do |p,_|
          projects << p
        end
        tfs.files = projects.collect_concat do |p| 
          [p.project_file,p.output]          
        end
      end
      
      # Update versions
      task version_task_name(vbp_file) => tfs_co_task_name(vbp_file) do
        version=Conf::Build.version(product)
        # Update the version number and back up project files
        project.recursively do |p,_|
          p.version=version
          p.backup
          # Set file descriptions to include build timestamps
          p.version_file_description=Conf::Build.description(product)
        end
      end
      task name => version_task_name(vbp_file)

      # Compile the project and its dependents in the correct order
      task name do
        project.compile
        Common.logger.info("Built #{Conf::Build.product_name(product)}"+
                           " (#{File.basename(vbp_file)})"+
                           " v.#{Conf::Build.version(product)}")
      end
      [name]
    end

    def generate_build_msi_tasks            
      task build_msi_task_name(vbp_file) => build_task_name(vbp_file) do
        # Restore project files (so project references are kept intact
        # after compilation)
        project.recursively do |p,_|
          p.restore
        end
      end
      [build_msi_task_name(vbp_file)]
    end

  end

end

# Yields to the given code block, the product names given in
# config/environment.yml.  The first invocation of this method also
# results in a sanity check that verifies the existence of project
# files and TFS root directory for each product.

# All methods may be invoced with a code block as the last parameter,
# which can be accessed explicitly by prefixing the last parameter
# name with '&'. By using yield you can use this parameter without
# giving it a name. For more information on the yield construct, see
# http://www.tutorialspoint.com/ruby/ruby_blocks.htm

def each_product
  @products ||= Conf::Environment.products# .collect do |product|
  #   root=Conf::Src.project_root(product)
  #   non_existent_project_files = Conf::Src.project_files(product.to_s).select {|f| !File.exist?(f) }
  #   if !File.exists?(root)
  #     raise "Illegal TFS root in config/src.yml: #{root}"
  #   elsif !non_existent_project_files.empty?
  #     raise "Illegal project file(s) in config/src.yml:"+
  #       " #{non_existent_project_files}"
  #   else
  #     product
  #   end
  # end
  @products.each {|p| yield(p) }
end

def task_generators(product)
  @task_generators ||= {}
  @task_generators[product] ||= TaskGenerator.create(product)
end

def get_tasks re
  Rake.application.tasks.select {|t| re =~ t.name }
end

def create_parallel_task parents_regexp, child_name
  parents=get_tasks parents_regexp
  parent_deps=parents.collect_concat {|t| t.prerequisites }
  TC::Common.logger.debug "enhanced Rake task #{child_name} with #{parent_deps} from #{parents_regexp.inspect}"
  Rake::Task[child_name].enhance(parent_deps)
end

def inject_before(parents_regexp,child_name)
  parents=get_tasks parents_regexp
  parents.each do |parent| 
    before parent do
      Rake::Task[child_name].invoke 
    end
  end
  TC::Common.logger.debug "injected #{child_name} before #{parents.join ', '}"
end

def inject_after(parents_regexp,child_name)
  parents=get_tasks parents_regexp
  parents.each do |parent| 
    after parent do 
      Rake::Task[child_name].invoke 
    end
  end
  TC::Common.logger.debug "injected #{child_name} after #{parents.join ', '}"
end

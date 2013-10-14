require 'common'
require 'config/src'
require 'config/environment'
require 'tcfileutils'
require 'pathname'
require 'command'
require 'fileutils'
require 'projects/project'

module TC  

  module VB6

    def compile_command
      Conf::Command.vb6
    end

    def get_guid_command
      File.join(BINDIR,"GetGuid","GetGuid.exe")
    end

    def all_projects(root)
      # Get all vb6 projects for a product, to resolve dependencies 
      # if they are not contained within a project group
      vbp_pattern="#{root}/**/*\.vbp".gsub(%r{\\+},'/')
      @@all_projects ||={}
      @@all_projects[root] ||= FileList[vbp_pattern].collect do |f|
        VB6Project.new f,root
      end
    end

    attr_accessor :log_file

  end

  class VB6Project < Project
    include VB6

    attr_reader :compile_mode, :root

    def initialize(file,root)      
      super(file)
      @root=root
      @compiled=false
      @log_file="vb6_build.log"
      @compile_mode=:partial
    end

    def compile_mode=(mode)
      raise "Unknown compile mode: #{mode}" unless [:full,:partial].include? mode
      @compile_mode=mode
    end

    def project_file_name
      File.basename(@project_file)
    end

    # Update the project file, set CompatibleMode="#{compat}"
    def binary_compatibility=(compat)
      set_value("CompatibleMode",compat)
    end

    def description=(desc)
      set_value("Description",desc)
    end

    def version_file_description=(desc)
      set_value("VersionFileDescription",desc)
    end

    def dll?
      /\.dll$/i =~ exename
    end

    def ocx?
      /\.ocx$/i =~ exename
    end

    def exe?
      /\.exe$/i =~ exename
    end

    def name
      exename.gsub(/\..*/,'')
    end

    def exename
      get_value(/ExeName32="(.*)"/i)
    end
    
    def output_path
      path32=get_value(/Path32="(.*)"/i)
      # If Path32 is not specified, assume the project directory
      Pathname.new(File.dirname(@project_file))+(path32 ? path32 : "." )
    end

    def output
      (output_path+exename).to_s
    end

    def guid
      result=Command.run(get_guid_command,%Q["#{output}"])
      result[:stdout].strip
    end

    # Given a dependency name +name+, update the dependency so that the Reference.. 
    # line in the project file points to the output dll of the project
    # Reference=*\G{23685CD6-8D57-4652-88A8-6106F7EBBDF4}#1.0#0#..\..\Bin\TCLang42.dll#TCLang42
    def update_dependency(name,output,guid)
      relative_output=Pathname.new(output).relative_path_from(Pathname.new(File.dirname(project_file))).to_s
      TCFileUtils.gsub(@project_file,Regexp.new("Reference=.*?#{name}.*?$"),"Reference=*\\G#{guid}\#1.0\#0\##{relative_output}\##{name}")
    end

    def set_value(name,value)
      TCFileUtils.gsub(@project_file,Regexp.new("(#{name}=\"?)[^\"]+?(\"?)$"),"\\1#{value}\\2")
    end

    def version
      major=get_value(/MajorVer=(.*)/)
      minor=get_value(/MinorVer=(.*)/)
      revision=get_value(/RevisionVer=(.*)/)
      [major,minor,revision].join(".")
    end

    # Update the following parts of the vbp file:
    # MajorVer=4
    # MinorVer=2
    # RevisionVer=3033
    def version=(version)
      major,minor,revision=version.split(".")
      set_value("MajorVer",major)
      set_value("MinorVer",minor)
      set_value("RevisionVer",revision)
      Common.logger.debug("Updating #{name} to v.#{version}")
    end

    def dependency_dlls
      get_values(/Reference=\*\\G{.*}#.*#\d+#.*\\(\w+\.dll)#/i)
    end

    def dependency_project_file_names
      get_values(/Reference=\*\\A(.*\.(vbp))/i).collect do |name| 
        # Extract the base names excluding the path component
        /([^\\]+\.vbp)/i.match(name)[1] 
      end
    end

    def dll_ref?(other_project)
      dependency_dlls.include?(other_project.exename)
    end

    def project_ref?(other_project)
      dependency_project_file_names.include?(other_project.project_file_name)
    end

    def dependencies
      all_projects(root).select do |other_project| 
        # this project depends on projects explicitly referred to as projects
        # and on projects that produce dll:s this project depend on 
        project_ref?(other_project) || dll_ref?(other_project)           
      end
    end

    # Recursively traverse the dependencies of this project and its
    # children
    def recursively(parent=self,&block)
      dependencies.each do |child| 
        child.recursively(self,&block)
      end
      yield self,parent
    end

    def update_versions(version)
      recursively do |p,_|
        p.version=version
      end
    end
  
    def compile
      recursively do |p,parent| 
        # Only recompile dll references if doing a full recompile
        if !p.compiled? && (p==parent || parent.project_ref?(p) || parent.compile_mode==:full)
          p.make
        end
        if !parent.compiled? && (p != parent)
          Common.logger.debug("Updating #{parent.name} with references to the dll of #{p.name}")
          parent.update_dependency(p.name,
                                   p.output,
                                   p.guid) 
        end
      end
    end

    def make
      # self.binary_compatibility=1 if ocx?
      options = dll? ? "/makedll " : "/make "
      options += %Q[/out "#{log_file}"]
      # Delete output file if it exists
      FileUtils.rm log_file if File.exist? log_file

      Command.run(compile_command, %Q["#{@project_file.to_win_path}" #{options}])
      # Log the results of the output file and delete it
      Common.logger.merge_log_from(log_file,compile_command)
      # self.binary_compatibility=0 if ocx?
      @compiled=true
    end

    def compiled?
      @compiled
    end

  end

  class VB6ProjectGroup < Project

    attr_reader :startup_project, :projects
    include VB6

    def initialize(vbg_file, root)
      super(vbg_file)
      @projects=get_values(/^Project=(.*\.vbp)/i).collect do |value| 
        VB6Project.new(relative_to_absolute_path(value),root) 
      end
      value=get_value(/^StartupProject=(.*\.vbp)/i)
      startup_project_file=relative_to_absolute_path(value)
      @startup_project = VB6Project.new(startup_project_file,
                                        root)
    end
    
    def make
      startup_project.compile
    end

    def version=(version)
      startup_project.update_versions version
    end

  end
end

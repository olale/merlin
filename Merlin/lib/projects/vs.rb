# -*- coding: iso-8859-1 -*-
require 'nokogiri'
require 'projects/project'
require 'tcfileutils'

module TC

  class VSSolution

    attr_reader :sln_file, :project_pattern

    def initialize(sln_file)
      @sln_file=sln_file      
      @project_pattern = /Project(.*?) = "(?<name>.*?)", "(?<project_file>.*?)", "(?<guid>.*?)"/
    end

    def projects
      @projects||=get_projects
    end

    # Project types associated with *proj files
    def vs_projects
      projects.select {|project| [VSProject, VDProj].include? project.class }
    end

    # Detect these entries in the .sln file:
    # Project("{54435603-DBB4-11D2-8724-00A0C9A8B90C}") = "ProductSetup", "ProductSetup\ProductSetup.vdproj", "{6AE7FB79-1F4C-4810-BC0B-BA317E1DCEC6}"
    # EndProject
    # EXCEPT 
    # * the pseudo-project "Solution Items"
    def get_projects
      project_files.collect do |f|
        (/\.((vb)|(cs))proj$/ =~ f ? VSProject : VirtualProject).new(f)
      end
    end

    def project_files
      sln_dir=Pathname.new(sln_file).dirname
      files = []
      File.open sln_file do |f|
        while line=f.gets
          match=project_pattern.match line
          if match && match['name'] != 'Solution Items'
            project_relative_path= match['project_file'].from_win_path
            files << (sln_dir+project_relative_path).to_s
          end
        end
      end
      files
    end

  end

  class VirtualProject

    attr_reader :project_file

    def initialize(project_dir)
      @project_file=project_dir
    end
       
    def asm_file
      Dir[@project_file.from_win_path+"/**/AssemblyInfo.{cs,vb}"][0]
    end

  end

  class VSProject < Project

    module ProjectTypeGuid
      # See http://www.mztools.com/articles/2008/mz2008017.aspx
      MSTEST="{3AC096D0-A1C2-E12C-1390-A8335801FDAB}"      
    end

    attr_reader :doc

    def initialize(project_file)
      super(project_file)
      @doc=Nokogiri::XML(File.open(project_file))
    end

    def project_type_guids
      doc.css('PropertyGroup > ProjectTypeGuids').text
    end

    def mstest?
      /#{ProjectTypeGuid::MSTEST}/ =~ project_type_guids
    end

    def output_name
      absolute_output_path + assembly_name + ".dll"
    end

    def absolute_output_path
      relative_to_absolute_path output_path 
    end

    def output_path
      doc.css('PropertyGroup[Condition*=Release] > OutputPath').text
    end

    def assembly_name
      doc.css('PropertyGroup > AssemblyName').text
    end
   
    def asm_file
      Dir[File.dirname(project_file).gsub(%r{\\},"/")+"/**/AssemblyInfo.{cs,vb}"][0]
    end

  end

  class VDProj < Project
        
    alias_method :vdproj_file, :project_file

    # "OutputFilename" = "8:x64\\FooAPISetup.msi"
    def outputs
      get_string_values("OutputFilename").collect{ |p| relative_to_absolute_path(p) }
    end

    def get_string_value(name)
      get_value(/"#{name}" = "8:(.*?)"/)
    end

    def get_string_values(name)
      get_values(/"#{name}" = "8:(.*?)"/)
    end

    def set_string_value(name,value)
      TCFileUtils.gsub(project_file,/("#{name}" = "8:).+(")/, "\\1#{value}\\2")
    end

    def version
      get_string_value "ProductVersion"
    end

    def version=(v)
      set_string_value "ProductVersion", v
    end

    def subject=(s)
      set_string_value "Subject", s
    end

    def subject
     get_string_value "Subject"
    end

    # Retrieve the only product code entry that contains a UUID 
    def product_code
      get_value(/"ProductCode" = "8:({.*?})"/)
    end

    # Change the "ProductCode" entry that contains an UUID (there are several entries in the vdproj, 
    # most of which have nothing to do with the product code, curiously)
    def product_code=(uuid)
      TCFileUtils.gsub(project_file,/("ProductCode" = "8:){.*}(")/, "\\1#{uuid}\\2")
    end

    def package_code=(uuid)
      set_string_value "PackageCode", "#{uuid}"
    end

    def upgrade_code=(uuid)
      set_string_value "UpgradeCode", "#{uuid}"
    end

  end
  
end

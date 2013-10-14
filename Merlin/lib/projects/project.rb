require 'pathname'
require 'tempfile'
require 'fileutils'

module TC
  class Project
    attr_reader :project_file

    def initialize(file)
      @project_file=file
    end

    # Convert a path relative to the project file to an absolute path
    def relative_to_absolute_path(value)
      project_relative_path=value
      (Pathname.new(File.dirname(project_file))+project_relative_path).to_s
    end

    # Assuming a pattern with one capture group
    def get_value(pattern)
      File.open(project_file) do |f|
        line = f.readlines.find { |l| pattern =~ l }
        $1
      end
    end

    # Assuming a pattern with one capture group
    def get_values(pattern)
      File.open(project_file) do |f|
        lines = f.readlines.select { |l| pattern =~ l }
        lines.map { |l| pattern.match(l)[1] }
      end
    end

    def ==(project)
      project.is_a?(Project) && project_file==project.project_file
    end

    def backup
      @backup_file = Tempfile.new(File.basename(@project_file))
      FileUtils.cp @project_file, @backup_file.path
    end

    def restore
      raise "No backup file exists" unless @backup_file && File.exist?(@backup_file.path)
      FileUtils.cp @backup_file.path, @project_file
    end

  end
end

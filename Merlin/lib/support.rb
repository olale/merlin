require 'logger'
require 'rake' # FileList
require 'socket'

class Class
  def simple_name
    to_s.split(/::/)[-1].downcase
  end  
end

module Kernel
  def get_binding
    binding
  end
end

class Array

  def globs_to_paths(basedir=".",product=TC::Conf::Environment.product, env=TC::Conf::Environment.env)
    self.collect_concat do |glob|
      glob.to_paths(basedir,product,env)
    end
  end

end

# Encoding.default_external = "UTF-8"
# Encoding.default_internal = "UTF-8"

class String
  
  def to_win_path
    encode('Windows-1252').gsub(%r{/},"\\")
  end
  
  def from_win_path
    encode('UTF-8').gsub(%r{\\},"/")
  end  

  def to_paths(basedir=".",product=TC::Conf::Environment.product, env=TC::Conf::Environment.env)
    dir=basedir+(basedir.end_with?("/") ? "" : "/")
    dir=dir.from_win_path
    FileList["#{dir}#{self}".expand_template(product,env)]
  end

  def expand_template(product=TC::Conf::Environment.product, env=TC::Conf::Environment.env)
    product_template=/<product>/
    env_template=/<env>/
    self.gsub(product_template, product).gsub(env_template,env)    
  end

  def local_address?
    normalized_name= self.upcase
    normalized_name == "LOCALHOST" || normalized_name == Socket.gethostname
  end

  def to_version
    scan(/\d+/).collect {|v| v.to_i}
  end

  def version_gte(other_string)
    different_versions=to_version.zip(other_string.to_version).find { |this_version,other_version| this_version != other_version }
    this_version_number,other_version_number=different_versions
    !different_versions || this_version_number >= other_version_number
  end

  def version_gt(other_string)
    this_version,other_version=to_version.zip(other_string.to_version).find { |this_version,other_version| this_version != other_version }    
    this_version && this_version > other_version
  end

end

class Logger::LogDevice
  def add_log_header(file)
    file.write "TC Log file created %s\n" % Time.now.to_s
  end
end

module TC
  
  BASEDIR     = File.expand_path("..",File.dirname(__FILE__))
  LIBDIR      = "#{BASEDIR}/lib"
  BINDIR      = "#{BASEDIR}/bin"
  TESTDIR     = "#{BASEDIR}/test"
  CONFDIR     = "#{BASEDIR}/config"
  TASKDIR     = "#{BASEDIR}/tasks"
  TEMPLATEDIR = "#{BASEDIR}/templates"
  SQLDIR      = "#{BASEDIR}/sql"
  ASSETDIR    = "#{BASEDIR}/assets"
  
  def self.upgrade_dir_dest(product)
    "#{SQLDIR}/scripts/upgrade/#{product}"
  end
  
  def self.new_dir_dest(product)
    "#{SQLDIR}/scripts/install/#{product}"
  end

end

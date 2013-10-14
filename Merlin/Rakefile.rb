$LOAD_PATH << (File.dirname(__FILE__))
require 'init'

# MSBuild tasks and configuration
require 'albacore'
require 'config/albacore_config'
require 'config/environment'
require 'config/mail'

include TC
include Common
Rake.application.tty_output= false
all_tasks=FileList["#{TASKDIR}/*.rake"]


module Rake
  class Task
    
    def self.exception_handlers
      @exception_handlers ||= []
    end
    
    alias :orig_execute :execute
    def execute(args=nil)      
      orig_execute(args)
    rescue Exception => exception
      Task.exception_handlers.each do |handler|
        handler.call self
      end
      # Re-raise to abort
      raise exception
    end
  end

  class Application

    alias :orig_top_level :top_level

    # Hooks to run after loading all task definitions
    def self.post_init_hooks
      @post_init_hooks ||= []
    end

    def top_level
      Application.post_init_hooks.each do |hook|
        hook.call
      end
      orig_top_level
    end

  end
end

# Do we call Rake with only -P, -T?
include_compile = !ARGV.any? {|arg| !(/-/ =~ arg)}

# Or do we have a task related to a product? Only in such case, load the expensive compile.rake
include_compile ||= ARGV.any? { |arg| Conf::Environment.all_products.any? {|p| /#{p}/ =~ arg }}

enabled_tasks=all_tasks.reject do |t|
  Conf::Environment.disabled_products.any? { |p| /#{p}/ =~ File.basename(t,".rake") } ||
    (File.basename(t) == "compile.rake" && !include_compile)
end

enabled_tasks.each {|f| import f }

task :default do
  puts File.read("doc/README.txt")
end

desc "Clean all temporary files in this directory recursively"
task :clean do
  planning_dir = (Pathname.new(TESTDIR)+"unit"+"projects"+"files"+"planning").to_s.gsub(%r{\\+},"/")+"/"
  deletions = Dir[planning_dir+"**/*.{ctl,bas,cls,ctx,frm,frx,vbw,sql,exe,doc,wse,log,doc,docx,lib,SCC,exp}"]
  deletions += Dir[BASEDIR+"/{lib,config,tasks,test,emacs,dotfiles}/**/*{.log,~,flymake.rb}"]
  deletions += Dir[BASEDIR+"/devenv.out"]
  deletions += Dir[BASEDIR+"/TestResults/**/*"]
  deletions.each do |f|
    puts "deleting #{f}"
    FileUtils.rm_f f
  end
end

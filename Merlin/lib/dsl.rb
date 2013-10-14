# Class for DSL:s for migrations and DB verifications 
require 'wrong'

module TC
  module Dsl

    def file
      File.basename(@file)
    end

    def load(f)
      @file=f
      if /\.rb$/ =~ f
        instance_eval File.read(f), f
      end
    end

  end

  class Migrator
    include Dsl

    def initialize(f)
      load(f)
    end

    def migrate(&block)
      @migration=block
    end

    def run
      @migration.call
    end
    
  end

  class Verifier
    include Dsl

    # See https://github.com/sconover/wrong
    include Wrong

    attr_accessor :sql_runner

    def initialize(sql_runner,f)
      @sql_runner=sql_runner
      @tests = []
      @file=f
      if /\.rb$/ =~ f
        load(f)
        Common.logger.warn "No test block in '#{File.basename(f)}'"  if @tests.empty?
      elsif /\.sql$/ =~ f
        # SQL tests are assumed to return (select) 1 on success
        @tests = [{:msg =>"SQL SELECT ... => 1",:test => lambda { assert {"1" == sql_runner.get_result(f) }}}]
      else
        Common.logger.warn "Unknown test type: '#{File.basename(f)}'. Only *.{rb,sql} are recognized as test files"
      end
      @applicability_test ||= lambda {|_| true }
    end

    # version applicability can be specified either using a constant
    # version string, or a block that accepts a version number and
    # responds with a boolean value to indicate whether the tests in
    # the file are applicable to the given version
    def version(v=nil,&block)
      @applicability_test=v ? lambda {|arg| v == arg } : block
    end

    def applicable_to?(version)
      @applicability_test.call version
    end

    def test(msg=nil,&block)
      @tests << {:msg => msg, :test => block}
    end

    def run
      begin
        @tests.each do |t| 
          @current_test=t[:msg]
          t[:test].call
        end
      rescue Exception => e
        # Add file name and test name to the exception message for better readability
        msg = "DB Verification test '#{@current_test}' (#{file}) failed:\n#{e.message}"
        raise msg
      end
    end
    
  end
end

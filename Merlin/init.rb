dir=File.dirname(__FILE__)
$LOAD_PATH.unshift(File.join(dir,"lib/"))
$LOAD_PATH.unshift(File.join(dir,"test/"))

require "rubygems"
require "bundler/setup"
require 'find'
require 'rake'
require 'common'

# Always abort when one thread raises an exception
# Thread.abort_on_exception = true

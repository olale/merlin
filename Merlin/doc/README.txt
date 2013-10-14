This is a library for automating tasks related to development and
deployment

Installation:
	See INSTALL.txt

Layout: 

	bin/ - custom binaries used by the build scripts

	config/ - Setting files.  Setting format is YAML 1.1:
		   http://yaml.org/spec/1.1/

	contrib/ - source code for .Net projects with support
	            functionality.

	lib/ - Ruby classes

	Rakefile.rb - The starting point of the application. Run using
		   the command "rake".  Without arguments, lists
		   available tasks

	sql/ - ERb SQL templates for tasks such as restoring
		   databases, and static SQL scripts for retrieving DB
		   version.

	tasks/ - Rake tasks for functionality that is common to all
	       	   products or specific to only one of
	       	   them. Product-specific task files have names that
	       	   contain the product name

	test/ - Unit, configuration, and integration tests

Usage:
	In this directory, run "rake -T" to list all available tasks

Adding tasks:

       * Look at the files in the tasks folder, find one that fits for
         your task or add a new one.

       * All files matching the file name pattern "tasks/*.rake" are
         imported from Rakefile

       * Go to http://rake.rubyforge.org/ for documentation on Rake

Adding functionality:

       * Add functionality in lib by adding classes in separate files and test it
         using a new test in the directory test/. 

       * Configuration tests (test/config/*_test.rb) are run the task "test:config". 
       	 DB tests (test/db/*_integration.rb) are run using the task "test:db".
	 Unit tests (test/unit/**/*_test.rb) are run using the task "test:unit" or using autotest 
	 (see https://github.com/seattlerb/zentest)
	 Look at existing tests for inspiration.


**************************************
	Emacs
**************************************

You can use TFS from Emacs using keyboard shortcuts. See the end of
emacs/.emacs for a list of keybindings.

You can use Ruby interactively from Emacs. Start a Ruby console with
"C-c C-s" from a Ruby buffer. Type "C-c Alt-r" to send a region of
Ruby code (mark the whole buffer with "C-x h"). To bootstrap the
application from within Emacs, type the following in the Ruby console,
replace as appropriate to point to the base directory of this tool:

irb(main):0:0> $LOAD_PATH << "C:/TFS/TFS Tools/CommonProject/tc" 
irb(main):1:0> require 'init' # To set up additional paths and initial includes
irb(main):1:0> include TC     # To include the TC module in the object
                              # called "main"

Emacs can indent code for you by using TAB, so press TAB on any line
to indent properly.

There are lots of built-in commands and shortcuts, you can view which
ones are available from the help menu by looking at the current
"Buffer Mode" ("Help => Describe => Describe Buffer Modes" or "Help =>
Describe => List Key Bindings").


**************************************
	Rake
**************************************

Rake parameters:

# Simulate the execution of a task
rake --dry-run task

# List all prerequisites
rake -P

# List all available (described) tasks
rake -T

# Short description of how to interpret a task (from tasks/db.rake):

    desc "Upgrade the master DB for :product (default #{Conf::Environment.product})"
    task :upgrade, [:product] do |t,args|
      args.with_defaults :product => Conf::Environment.product
      upgrader = DbUpgrade.create(Conf::Database.master_config(args.product), args.product)
      upgrader.run
    end

# The Ruby method 'desc' provides a command line description of the Rake task. 
# Only tasks preceded by 'desc' are listed by 'rake -T'

    desc "Upgrade the master DB for :product (default #{Conf::Environment.product})"

# We create a Rake task by the name 'upgrade', using the symbol :upgrade, in the current namespace, 
# that takes a parameter 'product' and has no dependencies.

# To access the parameters provided, we must accept two parameters in the code block that follows 
# (named 't' and 'args' below), where the first parameter will be bound to the name of the task and
# the second will be bound to the parameters given

    task :upgrade, [:product] do |t,args|

# The default value for the 'product' parameter is given by the expression 'Conf::Environment.product'

      args.with_defaults :product => Conf::Environment.product

# 'args' is an object that responds to methods corresponding to the parameter names

      upgrader = DbUpgrade.create(Conf::Database.master_config(args.product), args.product)
      upgrader.run
    end



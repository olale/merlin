# -*- coding: utf-8 -*-
require 'config/build'
require 'config/environment'

module TC::GUI
  class Conf
    class << self
      attr_accessor :server, :db, :username, :password, :file_name, :backup_dir

      def product_name
        TC::Conf::Build.product_name(product)
      end

      def product
        exe_match=/(\w+)_db/.match(ENV["OCRA_EXECUTABLE"]) {|m| m[1]}
        exe_match || options[:product] || TC::Conf::Environment.product
      end

      def server
        @server ||= options[:server]
      end

      def db
        @db ||= options[:db]
      end

      def username
        @username ||= options[:username]
      end

      def password
        @password ||= options[:password]
      end

      def sspi?
        options[:sspi]
      end

      def batch?
        options[:batch]
      end
      
      def backup_dir
        @backup_dir ||= options[:backup_dir] || Etc.systmpdir
      end

      def current_setting
        "#{product_name} vid #{server}/#{db}"
      end

      def options
        @options ||= {}
        # Ignore command line arguments when running this script as a
        # standalone executable compiled by Ocra, in which case the
        # environment variable OCRA_EXECUTABLE is set to $0
        if @options.empty? && !ENV["OCRA_EXECUTABLE"]
          OptionParser.new do |opts|
            opts.banner = "Usage: ruby #{__FILE__} [options]"      
            opts.on("-p", "--product PRODUCT", "Select product") do |p|
              options[:product] = p
            end
            opts.on("-s", "--server SERVER", "Select server") do |p|
              options[:server] = p
            end
            opts.on("-d", "--database DATABASE", "Select database") do |p|
              options[:db] = p
            end
            opts.on("-u", "--username USERNAME", "SQL Server username") do |p|
              options[:username] = p
            end
            opts.on("-P", "--password PASSWORD", "SQL Server password") do |p|
              options[:password] = p
            end
            opts.on("-E", "--sspi", "Use Windows Authentication (SSPI)") do |p|
              options[:sspi] = true
            end
            opts.on("-b", "--batch", "Upgrade and close immediately") do |p|
              options[:batch] = true
            end
            opts.on("-B", "--backup_dir DIR", "backup directory") do |p|
              options[:backup_dir] = p
            end
          end.parse!
        end
        @options
      end

    end
  end
end


module TC

    class Packager

      attr_reader :product, :version

      def initialize(product=Conf::Environment.product,basedir)
        @product=product
        @version=Conf::Build.version(product)
        @basedir=basedir
      end

      def run_ocra script, output_name
        version=Conf::Build.version product
        test_configs=Conf::Database.configs(product,Conf::Environment::Settings::TEST)
        raise "No test db config given in config/database for #{product}" if test_configs.empty?
        db_config=test_configs.first
        file_args = ""
        file_args << %Q["#{CONFDIR}/*.yml" ]
        file_args << %Q["#{@basedir}/**/*" ]
        file_args << %Q["#{SQLDIR}/*" ]
        file_args << %Q["#{ASSETDIR}/*" ]
        # More files needed for distribution package?

        # To avoid having DOS windows pop up every time we run an external
        # command, we launch the GUI from a console
        ocra_options="--console "
        
        # We assume relative paths sometimes, so it is a good thing to start
        # in the application directory    
        ocra_options << "--chdir-first "

        # Necessary to avoid autoload issues with Active Record, see
        # https://github.com/larsch/ocra/issues/16
        ocra_options << "--no-autoload "
        
        # Do not delete extracted files after run in development mode
        ocra_options << "--debug-extract " if Conf::Environment.setting==Conf::Environment::Settings::DEVELOPMENT

        ocra_options << "--output #{output_name} "

        # Run the upgrade script with command line parameters, so as to
        # avoid having to fill in information in the GUI
        script_options="--product #{product} "
        script_options << "--batch " # exit upon completion
        script_options << "--backup_dir #{db_config.backup_dir} "
        # after upgrade
        script_options << "--server #{db_config.server} "
        script_options << "--database #{db_config.db} "
        if !(db_config.user && db_config.password)
          script_options << "--sspi " # Use Windows authentication
        else
          script_options << "--username #{db_config.user} "
          script_options << "--password #{db_config.password} "
        end
        Command.run "ocra", %Q[#{ocra_options} "#{script}" #{file_args} -- #{script_options}]
        Common.logger.info "Created #{output_name} from #{script}"
      end

    end


end


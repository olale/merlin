require 'db/db'

module TC

  class Dumper < Db

    ScriptDb = File.join(BINDIR,"ScriptDb","ScriptDb.exe")

    attr_reader :dump_path

    def initialize(conf,product)
      super(conf,product)
      @dump_path = conf.dump_path
      @dump_root=conf.dump_root
      if conf.tables
        @tables=conf.tables.join(",")
      else
        @datatables=Conf::Sql.dump_tables(product).join(",")
      end
    end

    # ScriptDb.exe command reference
    #   -h, -?, --help             Show this help.
    #   -x, --examples             Show examples of usage
    #   -V, --version              Show the version.
    #   -S, --server=SERVER        The SQL SERVER to which to connect (localhost if
    #                                unspecified)
    #   -d, --database=DATABASE    The DATABASE to script
    #   -A, --scriptalldatabases   Script all databases on the server, instead of
    #                                just one specified database
    #   -U, --login, --uid, --username=LOGIN
    #                              The SQL LOGIN ID (Use trusted auth if
    #                                unspecified)
    #   -P, --pwd, --password=PASSWORD
    #                              The SQL PASSWORD
    #       --outdir, --outputpath, --outputdirectory=DIRECTORY
    #                              The DIRECTORY under which to write script files.
    #       --outfile, --filename, --outputfilename=FILENAME
    #                              The FILENAME to which to write scripts, or - for
    #                                stdout.
    #   -v, --verbose              Show verbose messages.
    #       --purge                Delete files from output directory before
    #                                scripting.
    #       --includedatabase, --scriptdatabase
    #                              Script the database itself.
    #       --dataformat=FORMAT    Specify the FORMAT for scripted table data: SQL
    #                                (default), CSV, and/or BCP.
    #       --datatables[=NAME]    Script table data, optionally specifying NAMEs
    #                                of tables. (Default all)
    #       --datatablefile=FILENAME
    #                              FILENAME containing tables for which to script
    #                                data for each database name. File format:
    #                                database:table1,table2,table3
    #       --tables[=NAME]        Script table schema, optionally specifying NAMEs
    #                                of tables. (Default all)
    #       --views[=NAME]         Script view schema, optionally specifying NAMEs
    #                                of views. (Default all)
    #       --sps, --storedprocs, --storedprocedures[=NAME]
    #                              Script stored procedures, optionally specifying
    #                                NAMEs. (Default all)
    #       --tableonefile         Script all parts of a table to a single file.
    #       --scriptascreate, --scriptstoredproceduresascreate
    #                              Script stored procedures as CREATE instead of
    #                                ALTER.
    #       --createonly           Do not generate DROP statements.
    #   -p, --scriptproperties     Script extended properties.
    #       --permissions, --scriptpermissions
    #                              Script permissions.
    #       --statistics, --scriptstatistics
    #                              Script statistics.
    #       --nocollation          Skip scripting collation.
    #       --startcommand=COMMAND COMMAND to run on startup.
    #       --prescriptingcommand=COMMAND
    #                              COMMAND to run before scripting each database.
    #       --postscriptingcommand=COMMAND
    #                              COMMAND to run after scripting each database.
    #       --finishcommand=COMMAND
    #                              COMMAND to run before shutdown.

    # If you do not pass any of the filter parameters --tables, --views, or --storedprocedures,
    # then all objects will be scripted. If you do pass a filter parameter, then you must
    # specify all the objects you want scripted. For example, passing only --tables will
    # prevent any views or stored procedures from being scripted.

    # Commands can include these tokens:
    # {path} - the output directory
    # {server} - the SQL server name
    # {serverclean} - same as above, but safe for use as a filename
    # {database} - the database name
    # {databaseclean} - same as above, but safe for use as a filename
    # The outDir parameter can also use all these tokens except {path}.
    # {database} is meaningful in StartCommand, FinishCommand and outDir only when
    # just a single database is specified in the connection string to be scripted.
    def run
      options=""
      options << "--scriptascreate " 
      options << "--verbose "
      # Data dumps should not purge other structure dumps
      options << "--purge " unless @tables
      options << "--permissions "
      options << "--server=#{server} "
      options << "--database=#{db} "
      if user && password
        options << "--username=#{user} "
        options << "--password=#{password}"
      end
      options << %Q[--outputdirectory="#{dump_path}" ]
      # Only script data for variants
      if @tables
        options << "--tables:#{@tables} "
        options << "--datatables:#{@tables} "
      else
        options << "--datatables:#{@datatables} "
      end
      Command.run ScriptDb, options 
      Common.logger.info "Dumped #{@tables ? 'tables '+@tables : 'the DB structure'} of #{setting} to #{@dump_root}"
    end
  end


  class MasterDumper < Dumper

    def self.dump_variants(product)
      variants=Conf::Database.variant_configs product
      variant_dumpers=variants.collect {|v| Thread.new { new(v,product).run } }
      variant_dumpers.each {|thread| thread.join }
    end

    attr_accessor :dry_run

    def run
      TFS.get @dump_root
      TFS.checkout @dump_root, "/recursive"
      super
      TFS.undo_unmodified @dump_root      
      changes=TFS.online(@dump_root,dry_run)[:stdout]
      Common.logger.info "#{dry_run ? 'Preview' : 'Staged'} all pending changes to #{db} structure at #{@dump_root}"
      changes
    end

  end

end

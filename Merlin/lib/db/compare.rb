require 'db/db'
require 'tcfileutils'

module TC

  class Compare < Db
    
    def self.create(config,product,mode)
      raise "Unknown comparison mode: #{mode}" unless ["ocdb","diff"].include? mode
      mode == "ocdb" ? OCDBCompare.new(config,product) : DiffCompare.new(config,product)
    end

    def initialize(config, product)
      super(config,product)
      @config=config      
    end

    attr_accessor :master_config

    def master_config
      @master_config ||= Conf::Database.master_config(product)
    end

    def result
      @result||=compare
    end
    
    def run
      if master_config.server && master_config.db
        comparison=File.read result
        Common.logger.debug comparison
        if comparison.empty?
          Common.logger.info "no differences found"
        else
          report_file="diff_report.txt"
          FileUtils.cp result, report_file
          Common.logger.info "differences found. Please inspect #{report_file} for more information"
        end
      else
        Common.logger.error("No master Server and DB to compare against")
      end
      comparison
    end

    # An empty difference result means two databases are equal w r t their structure
    def equal?
      result.empty?
    end

  end

  class OCDBCompare < Compare

    OCDB=File.join(BINDIR,"OpenDBDiff","OCDB.exe")

    def cn1
      cn server,db,user,password
    end

    def cn2
      cn(master_config.server,
         master_config.db,
         master_config.user,
         master_config.password)
    end

    def compare
      suffix=Time.now.strftime("%Y%m%d_%H%M")      
      output_file=Tempfile.new "dbdiff.sql"
      output_file.close
      Command.run(OCDB, %Q[CN1=#{cn1} CN2=#{cn2} F="#{output_file.path.to_win_path}"])
      output_file.path
    end

  end

  class DiffCompare < Compare

    LDiff="ldiff"

    attr_writer :dump

    attr_reader :content_diffs, :file_diff, :master_dump_root, :db_dump_root

    def initialize(config, product)
      super(config,product)
      @dump=true
    end

    def compare
      if @dump
        Dumper.new(@config,product).run
        # Dumper.new(master_config,product).run
      end
      @master_dump_root=master_config.dump_root.from_win_path
      @db_dump_root=@config.dump_root.from_win_path
      master_dump_files = Dir[master_dump_root+"/**/*"]
      db_dump_files = Dir[db_dump_root+"/**/*"]

      # Strip the path prefixes so we can compare the relative path names
      expected_file_names = master_dump_files.collect { |f| f.sub master_dump_root, "" }
      actual_file_names = db_dump_files.collect { |f| f.sub db_dump_root, "" }
      expected_file=TCFileUtils.to_tmp_file expected_file_names.join("\n")
      actual_file=TCFileUtils.to_tmp_file actual_file_names.join("\n")
      FileUtils.cp expected_file, "expected_file.txt"
      FileUtils.cp actual_file,   "actual_file.txt"  
      # For some unknown reason, ldiff don't seem to detect any
      # difference between two temp files, so we have to copy them to
      # the local folder...
      @file_diff = Command.run(LDiff, %Q[-a actual_file.txt expected_file.txt])[:stdout]
      FileUtils.rm "expected_file.txt"
      FileUtils.rm "actual_file.txt"
      @content_diffs = {}
      
      (expected_file_names & actual_file_names).each do |f|
        expected_file= master_dump_root+f
        actual_file= db_dump_root+f
        if File.file? expected_file
          # Faster using SHA digests?
          # actual_hash=Digest::SHA256.file(actual_file).hexdigest
          # expected_hash=Digest::SHA256.file(expected_file).hexdigest
          # eq = (actual_hash == expected_hash)
          diff = Command.run(LDiff, 
                            %Q["#{actual_file.to_win_path}" "#{expected_file.to_win_path}"])[:stdout]
          @content_diffs[f] = diff unless diff.empty?
        end
      end

      TCFileUtils.file_from_template("#{TEMPLATEDIR}/diff_report.txt.erb", self)
    end

  end

end

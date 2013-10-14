require 'db/upgrade'
require 'db/backup'
require 'db/restore'
require 'db/compare'

module TC
  class MultiDb

    class << self
      def upgrade(configs,product)
        mode=Conf::Sql.upgrade_mode(product)
        upgrade_class = mode=='legacy' ? TC::LegacyUpgrade : TC::DbUpgrade
        new(upgrade_class,configs,product)
      end

      def backup(configs,product)
        new(Backup,configs)
      end

      def restore(configs,product)
        new(Restorer,configs,product)
      end

      def compare(configs,product)
        new(Compare,configs,product)
      end

    end

    attr_reader :actions

    def initialize(klass,configs,product)
      if configs.empty?
        Common.logger.warn "No configuration files found in config/database for #{product}"
        @actions = []
      else
        @actions = configs.collect {|c| klass.send :new,c,product }
      end
    end    

    def run
      # threads=[]
      actions.each do |a| 
        a.run # threads << Thread.new { a.run }
      end
      # threads.each {|t| t.join }
    end

  end
end

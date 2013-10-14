require 'config/environment'
require 'config/src'
require 'pathname'

module TC

  module Conf
    class Sql < YamlConf

      # Initialize with a default config-based lookup of DB upgrade
      # runorder, with override possible
      def initialize
        @legacy_upgrade_run_order = Hash.new {|hash,product_name| install_config(product_name)['files'] }
      end

      # Override the DB upgrade run order for +product+
      def set_run_order_for_product(product,run_order)
        @legacy_upgrade_run_order[product]=run_order
      end

      def dump_tables(product=Environment.product)
        self[product]['dump_tables']
      end

      def install_config(product=Environment.product)
        self[product]['install']
      end

      def install_dir(product=Environment.product)
        (Pathname.new(Src.project_root(product))+
         install_config(product)['dir']).to_s
      end

      def install_files(product=Environment.product)
        @legacy_upgrade_run_order[product]
      end

      def upgrade_mode(product=Environment.product)
        self[product]['mode']
      end

      def legacy?(product=Environment.product)
        self[product]['mode']=="legacy"
      end

      # For modern upgrades
      def upgrade_dir(product=Environment.product)
        glob=File.join(Conf::Src.project_root(product),Conf::Sql.upgrade_files).from_win_path
        (Pathname.new(Dir[glob].first)+"../..").to_s
      end


    end
  end
end

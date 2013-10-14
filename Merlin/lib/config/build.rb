require 'configuration'
require 'config/environment'

module TC
  module Conf
    class Build < YamlConf
      
      include Conf

      # timestamp: the time stamp of the current build
      # nightly: flag to indicate nightly builds
      attr_accessor :timestamp, :nightly
      
      def version(product=Environment.product)
        self[product]['version']
      end

      def previous_version(product)
        modified_version(product) {|revision| revision - 1 }
      end

      def next_version(product)
        modified_version(product) {|revision| revision + 1 }        
      end

      def modified_version(product,&block)
        current_version=version(product)
        version_numbers=current_version.split(".")
        # Modify the revision number
        revision_string=version_numbers.last
        revision = yield revision_string.to_i
        # Zero-fill the revision number string to the length defined
        #  in the build.yml config file
        revised_version=version_numbers[0..-2] << ("%0#{revision_string.length}d" % revision)
        revised_version.join "."
      end

      def version_bump(product=Environment.product)
        self[product]['version']=next_version(product)
      end

      def product_name(product=Environment.product)
        self[product]['name']
      end

      def destination(product=Environment.product)
        "#{self[product]['destination'].to_win_path}"
      end

      def description(product)
        nightly ? timestamp : ''
      end

      def nightly_destination(product)    
        File.join(destination(product),"NightlyBuilds",version(product),timestamp).to_win_path
      end

    end
  end
end

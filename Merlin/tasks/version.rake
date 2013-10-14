require 'tasklib'
require 'config/build'
require 'config/build'

each_product do |product|
  
  namespace product do
    product_name = Conf::Build.product_name(product)

    namespace :version do
      desc "Bump the version of #{product}"
      task :bump do
        file=File.join(CONFDIR,"build.yml")
        TFS.checkout file
        Conf::Build.version_bump product
        Conf::Build.save!
        comment="Bumped '#{product}' to v.#{Conf::Build.version(product)}"
        TFS.checkin file, comment
        Common.logger.info comment
      end
    end
  end
end

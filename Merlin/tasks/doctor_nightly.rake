require 'config/build'

namespace 'doctor' do

  task :create_db_upgrade_package do
    Common.logger.warn "DB Upgrade package not automated for #{Conf::Build.product_name('doctor')}"
  end

end

require 'configuration'
class TC::Conf::Environment < TC::Conf::YamlConf
  include TC::Conf
  module Settings
    TEST='test'
    DEVELOPMENT='development'
    PRODUCTION='production'
  end

  module Products
    PLANNING='planning'
    POOL='pool'
    DOCTOR='doctor'
  end

  class << self
    
    def all_settings
      [Settings::TEST,Settings::DEVELOPMENT,Settings::PRODUCTION]
    end
    
    def all_products
      [Products::PLANNING,Products::POOL,Products::DOCTOR]
    end

    def disabled_products
      all_products-products
    end

  end
  
end

require 'test_base'

class DbSettingsTest < TestBase

  def environments
    [Conf::Environment::Settings::DEVELOPMENT,
     Conf::Environment::Settings::PRODUCTION]
  end

  def test_invalid_variant
    flunked=false
    v="invalid_variant"
    begin
      Conf::Database.variant_config(product,v)
      # No errors will result in failure, everything else is
      # considered a success
    rescue Exception => e
      Common.logger.debug e.message
      flunked=true      
    end
    # If we come here without exception handling, flunk
    flunk "there should not be a variant '#{v}'" if !flunked
  end

  def test_databases_exist
    products.each do |p|
      environments.each do |e|
        Conf::Database.configs(p,e).each do |c|
          assert Db.new(c).db_exists?, "invalid database settings in #{c.file_name}"
        end
      end
    end
  end


end

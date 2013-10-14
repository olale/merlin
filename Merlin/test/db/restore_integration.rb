require 'test_base'
require 'db'

class RestoreIntegrationTest < TestBase

  def setup
    @loader = MultiDb.restore(Conf::Database.configs(product,env),product)
  end

  def test_restore_db
    begin
      @loader.run
    rescue Exception => e
      # Exceptions will result in failure, everything else is
      # considered a success
      flunk e.message
    end
  end

end

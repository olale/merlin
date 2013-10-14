require 'main'
require 'pathname'
$LOAD_PATH << "c:/"
require 'init'

require 'ostruct'
require 'db'

Main do

  argument('db')
  argument('server') 
  argument('username')
  argument('password')
  argument('product')

  mode 'restore' do

    argument('bak_file')

    def run
      config=OpenStruct.new
      config.db       =       params['db'].value
      config.server   =   params['server'].value
      config.username = params['username'].value
      config.password = params['password'].value
      config.bak_file = params['bak_file'].value
      TC::Restorer.new(config,params['product'].value).run
    end

  end

end

begin
  require 'wirble'
  require 'awesome_print'

  # init wirble
  Wirble.init
  # Wirble.colorize
rescue LoadError => err
  $stderr.puts "Couldn't load Wirble: #{err}"
end

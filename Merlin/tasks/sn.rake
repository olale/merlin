require 'config/environment'
require 'compile'

namespace :sn do

  desc "Detect missing key store entries for product (default: #{Conf::Environment.product}) based on msbuild failures."
  task :detect, [:product] do |t,args|
    args.with_defaults :product => Conf::Environment.product      
    SN.detect_missing(args.product)
  end

  # desc "List Strong Name settings"
  # task :list do
  #   TC::SN.list_settings
  # end

  # desc "Create Strong Name public file (#{Conf::Build.shared_key})"
  # task :makepublic do
  #   TC::SN.create_public_key(Conf::Build.private_key,
  #                            Conf::Build.shared_key)
  # end
end

require 'tfs'
require 'tasklib'

require 'tasklib'
require 'config/src'


each_product do |product|
  namespace product do

    product_name = Conf::Build.product_name(product)
    root=Conf::Src.project_root(product)
    namespace :tfs do  
      include TC

      desc "Undo changes to #{product_name}"
      task :undo do
        TFS.undo root
      end

      desc "Get source for #{product_name}"
      task :get do
        TFS.get root
      end

      desc "Check in changes to #{product_name}"
      task :checkin => :undo_unmodified do
        TFS.checkin root, "build @ #{Time.now}", "/recursive"
      end

      desc "Undo checkouts to unmodified files for #{product_name}"
      task :undo_unmodified do
        TFS.undo_unmodified root
      end

      desc "Apply a version label on #{product_name}"
      task :label => :checkin do
        TFS.label root, "Version #{Conf::Build.version(product)} @ #{Time.now}"
      end

    end
  end
end
namespace :tfs do  

  namespace :tc do

    desc "Get latest version"
    task :get do
      TFS.get BASEDIR, false
      Common.logger.info "Updated TC tool to latest TFS version"
    end

    desc "Undo unmodified files"
    task :uu do
      TFS.undo_unmodified BASEDIR
    end

    desc "Update and checkout this tool"
    task :update => :get do
      TFS.checkout BASEDIR, "/recursive"
    end

    desc "Check in changes to this tool"
    task :ckeckin, [:comment] => :uu do |t,args|
      args.with_defaults :comments => ""  
      TFS.checkin BASEDIR, args.comment, "/recursive"
      TFS.checkout BASEDIR, "/recursive"
    end

  end

end

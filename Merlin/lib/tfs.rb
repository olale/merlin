require 'common'
require 'command'
require 'config/command'
require 'config/build'

module TC
  include Common
  
  class TFS

    class << self

      def tf
        Conf::Command.tf
      end

      def tfpt
        # Defer lookup until execution as TFPT is not necessary for
        # simple get/checkout
        Conf::Command.tfpt
      end

      def run_tfs_command(command,p,options=nil)
        Command.run(tf,%Q[#{command} "#{p.to_win_path}" #{options}])
      end

      def status(p)
        run_tfs_command("status",p)
      end

      def get(path,overwrite=Conf::Build.overwrite)
        run_tfs_command("get",path,"/recursive"+(overwrite ? " /force" : ""))
      end

      def undo(path)
        Command.run(tf,%Q[undo /recursive "#{path.to_win_path}" /noprompt])        
      end

      def checkout(file,options="")
        options += "/recursive" if File.directory?(file) && !options.include?("/recursive")
        run_tfs_command("checkout",file,options)
      end

      def checkin(file,comment,options=nil)
        Command.run(tf,
                    %Q[checkin /comment:"#{comment}" /noprompt /override:"Auto-checkin using TC" #{options} "#{file.to_win_path}"])
      end

      def label(name,path,comment=nil)
        run_tfs_command("label",path,%Q[/comment:"#{comment}" /child:replace /recursive])
      end

      def undo_unmodified(path)
        Command.run(tfpt,%Q[uu "#{path.to_win_path}" /noget /recursive])
      end

      def online(path,dry_run=false)
        Command.run(tfpt,%Q[online /deletes /adds /diff /noprompt #{dry_run ? '/preview' : ''} "#{path.to_win_path}" /recursive])
      end
      
    end
  end

end

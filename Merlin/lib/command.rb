require 'open3'
require 'common'

module TC
  class Command

    class << self

      # Run +command+ interactively, by reading stdout and stderr
      # until +prompt+, then providing +i+ as input and continuing to
      # read both stdout and stderr until the command finishes
      def run_interactive(command,options=nil,prompt,i)
        cmd_name=File.basename(command)
        cmd = get_cmd(cmd_name,options)
        stderr=""
        stdout = ""
        status = 0
        Open3.popen3({"PATH" => File.dirname(command)},cmd) do |stdin,out,err,wait_thr|
          pid = wait_thr.pid
          thread_error = Thread.new(err) do |e|
            while (line=e.gets)
              stderr << line+"\n"
            end
          end
          # Wait for a prompt
          while (! (prompt =~ (line=out.gets)))
            stdout << line
          end
          stdin.puts i
          stdin.close
          stdout << out.read
          thread_error.join
          status = wait_thr.value
        end
        Common.logger.log_run(cmd_name,options,stderr,stdout,status)
        {:stdout => stdout,:stderr => stderr,:status=>status}
      end

      def get_cmd(command,options)
        "#{command} #{options}"
      end

      # Run a command with PATH augmented with the directory of the
      # command. Log the results of the command and return a hash with
      # :stdout (string), :stderr (string), and :status (ProcessStatus)
      def run(command, options=nil)
        raise %Q[No command given: "#{command}" #{options}] unless command
        cmd_name=%Q["#{command.from_win_path.split('/').last}"]
        cmd = get_cmd(cmd_name,options)
        Common.logger.log_running(command,options)
        path = File.dirname(command) 

        # Fill the PATH void for Windows commands by setting PATH 
        # to the dirname of the command run...
        env={}        
        if path != '.'
          env['PATH'] = ENV['PATH']+";"+File.dirname(command)
        end
        stdout, stderr, status = Open3.capture3(env,cmd)
        Common.logger.log_run(cmd_name,options,stderr,stdout,status)
        {:stdout => stdout,:stderr => stderr,:status=>status}      
      end

      def run_in_dir(command,options=nil)
        Dir.chdir(File.dirname(command)) do
          run(command,options) 
        end
      end

      def status_ok?(command,options=nil)
        run(command,options)[:status].exitstatus == 0
      end

      def stderr_empy?(command,options=nil)
        run(command,options)[:stderr].empty?
      end
      
    end

  end
end

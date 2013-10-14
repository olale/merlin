require 'mail'
require 'config/mail'
require 'socket'
require 'tasklib'

namespace :mail do

  task :setup do
    options = { 
      :address              => Conf::Mail.host,
      # :port                 => Conf::Mail.port,
      # :domain               => Conf::Mail.domain,
      # :user_name            => Conf::Mail.user_name,
      # :password             => Conf::Mail.password,
      # :authentication       => Conf::Mail.authentication,
      :enable_starttls_auto => true  }
    Mail.defaults do
      delivery_method :smtp, options
    end
  end

end

each_product do |product|

  namespace product do

    task :mail_build => "mail:setup" do |t,args|
      Common.logger.log_file.flush
      mail = Mail.new do
        from    Conf::Mail.from
        to      Conf::Mail.to
        subject "#{product} v.#{Conf::Build.version(product)} was built on '#{Socket.gethostname}'"
        body     <<END_OF_MESSAGE
#{File.read Conf::Logging.file}

#{Conf::Mail.from}
END_OF_MESSAGE

      end
      mail.deliver!
    end
    
    # Include mail after builds
    if Conf::Mail.mail_builds
      Rake::Application.post_init_hooks << proc do
        inject_after(/#{product}:build:build_msi_packages/,"#{product}:mail_build")
        inject_after(/#{product}:nightly:install/,"#{product}:mail_build")
      end
    end
  end
  
end

if Conf::Mail.mail_failures  
  Rake::Task.exception_handlers << proc do |task| 
    # Exception notification via e-mail
    Rake::Task["mail:setup"].invoke
    Common.logger.log_file.flush      
    s="rake #{task.name} failed on '#{Socket.gethostname}'"
    b=<<END_OF_MESSAGE
Failed to perform 'rake #{task.name}':
#{File.read Conf::Logging.file}

#{Conf::Mail.from}
END_OF_MESSAGE
    mail = Mail.new do
      from    Conf::Mail.from
      to      Conf::Mail.to
      subject s
      body    b
    end
    mail.deliver!
  end
end

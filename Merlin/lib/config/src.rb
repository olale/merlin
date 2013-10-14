require 'configuration'
require 'pathname'
require 'config/environment'

class TC::Conf::Src < TC::Conf::YamlConf

  class << self
    include TC::Conf
    
    def local_root_path
      Pathname.new(Environment.local_root)
    end

    def project_root_path(p=Environment.product)
      local_root_path + conf[p]['project_root']
    end

    def project_root(p=Environment.product)
      project_root_path(p).to_s
    end
    
    def projects(p=Environment.product)
      conf[p]['projects']
    end

    def project_files(p=Environment.product)   
      project_info_collection(p).collect {|h| h[:file] }
    end

    def project_info_collection(p=Environment.product)   
      @project_files ||= {}
      @project_files[p] ||= projects(p).collect_concat do |conf|
        glob = "#{project_root(p)}/#{conf['file']}".from_win_path
        tag = conf['tag']
        target = conf['target'] || 'x86'
        FileList[glob].collect do |f| { :file => f, :tag => tag, :target => target }
        end
      end
    end

    def project_file_path(project_conf,p=Environment.product)
      project_root_path(p)+project_conf['file']
    end
    
    def output_files(p=Environment.product)
      self[p]['output_paths'].globs_to_paths(project_root(p))
    end

  end
  
end

# -*- coding: iso-8859-1 -*-
require 'compile'
require 'tasklib'
require 'config/environment'
require 'config/src'
require 'config/build'


each_product do |product|
  namespace product do
    product_name = Conf::Build.product_name(product)
    task_gens = task_generators(product)

    tfsco :checkout => "#{product}:tfs:get" do |tfs|
      tfs.files   = Conf::Src.output_files(product)
    end
    
    build_tasks = task_gens.collect_concat {|t| t.build_tasks }
    desc "Build #{product_name}"
    task :build => build_tasks
        
    msi_creation_tasks = task_gens.collect_concat {|t| t.build_msi_tasks }

    namespace :build do
      
      tagged_task_generators = task_gens.select {|t| t.tag }
      task_generators_grouped_by_tag = tagged_task_generators.group_by(&:tag)
      
      task_generators_grouped_by_tag.each do |tag,task_generators|
        tagged_dependencies = task_generators.collect_concat { |t| t.build_tasks }
        desc "Build #{product}:#{tag}"
        task tag => tagged_dependencies
      end

    
      desc "Build generic MSI packages for #{product_name}"
      task :build_msi_packages => msi_creation_tasks

    end

    test_tasks=task_gens.collect_concat {|t| t.test_tasks }

    desc "Run MSTest test suites for #{product_name}"
    task :test => test_tasks

  end
end


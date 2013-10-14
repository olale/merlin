require 'pathname'
def run_tests(glob,use_turn=Conf::Environment.use_turn)  
  files=Dir['test/'+glob]
  test_path = Pathname.new('test')
  if use_turn
    require 'turn/autorun'
    Turn.config do |c|
      c.tests = files
      c.format = :cue
      c.ansi=true
    end
  end
  files.each do |file|
    path = Pathname.new(file)
    require (path.relative_path_from(test_path)).to_s
  end
end


namespace :test do

  task :init do
    $LOAD_PATH.unshift(TESTDIR)
    require 'test_base'
  end

  desc "Run unit tests (#{TESTDIR}/unit/**/*_test.rb)"
  task :unit => :init do
    run_tests("unit/**/*_test.rb")
  end

  desc "Run configuration tests (#{TESTDIR}/config/*_test.rb)"
  task :config => :init do
    run_tests("config/*_test.rb")
  end

  desc "Run DB tests (#{TESTDIR}/db/*_integration.rb)"
  task :db => :init do
    run_tests("db/*_integration.rb")
  end

  task :all => [:config, :unit, :db]

end

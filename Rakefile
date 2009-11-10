begin
  require "spec/rake/spectask"
  desc "Run all specs"
  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.libs = ['spec', 'lib']
    t.spec_opts = ["-c", "-f s"]
    t.ruby_opts = ["-r rubygems"] # If you want to use rubygems for requires
  end
rescue LoadError
  puts "RSpec not available. Can't run specs without it. Install with: sudo gem install rspec"
end

task :default => :spec

begin
  require "jeweler"
  Jeweler::Tasks.new do |gemspec|
    gemspec.name            = "divshare"
    gemspec.description     = "A Ruby interface to the DivShare file hosting service"
    gemspec.summary         = "A Ruby interface to the DivShare file hosting service"
    gemspec.require_paths   = ["lib"]
    gemspec.date            = Time.now.strftime("%Y-%m-%d")
    gemspec.files           = ["README", "LICENSE", "VERSION", Dir::glob("lib/**/**")].flatten
    gemspec.authors         = ["Eric Watson"]
    gemspec.email           = "wasnotrice@gmail.com"
    gemspec.homepage        = "http://github.com/wasnotrice/divshare"
    gemspec.rubyforge_project = "divshare"

    gemspec.add_dependency "hpricot"
    gemspec.add_dependency "mime-types"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

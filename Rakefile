begin
  require "spec/rake/spectask"
  desc "Run all specs"
  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.libs = ['spec', 'lib']
    t.spec_opts = ["-c", "-f s"]
    t.ruby_opts = ["-r rubygems"] # Remove to require dependencies another way
  end
rescue LoadError
  puts "RSpec not available. Can't run specs without it. Install with: sudo gem install rspec"
end

begin
  require "jeweler"
  Jeweler::Tasks.new do |gemspec|
    gemspec.name            = "divshare"
    gemspec.description     = "Makes it easy to use the DivShare API in Ruby"
    gemspec.summary         = "A Ruby interface to the DivShare file hosting service"
    gemspec.date            = Time.now.strftime("%Y-%m-%d")
    gemspec.files           = ["README", "LICENSE", "VERSION", "Rakefile", Dir::glob("lib/**/**")].flatten
    gemspec.authors         = ["Eric Watson"]
    gemspec.email           = "wasnotrice@gmail.com"
    gemspec.homepage        = "http://github.com/wasnotrice/divshare"
    gemspec.rubyforge_project = "divshare"

    gemspec.add_dependency "hpricot"
    gemspec.add_dependency "mime-types", ">= 1.16"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

task :default => :spec
task :build => :spec

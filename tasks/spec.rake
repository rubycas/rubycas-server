begin
  require 'rspec/core/rake_task'
  desc 'Run RSpecs to confirm that all functionality is working as expected'
  RSpec::Core::RakeTask.new('spec') do |t|
    t.rspec_opts = ['--colour', '--format nested']
    t.pattern = 'spec/**/*_spec.rb'
  end
rescue LoadError
  puts "Hiding spec tasks because RSpec is not available"
end


require 'spec/rake/spectask'
desc 'Run RSpecs to confirm that all functionality is working as expected'
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end

$: << File.dirname(File.expand_path(__FILE__))

# Try to load local version of Picnic if possible (for development purposes)
$: << File.dirname(File.expand_path(__FILE__))+"/../../../picnic/lib"
$: << File.dirname(File.expand_path(__FILE__))+"/../../vendor/picnic/lib"

begin
  require 'picnic'
rescue LoadError => e
  # make sure that the LoadError was about picnic and not something else
  raise e unless e.to_s =~ /picnic/
  
  require 'rubygems'
  
  # make things backwards-compatible for rubygems < 0.9.0
  unless Object.method_defined? :gem
    alias gem require_gem
  end
  
  gem 'picnic'
  
  require 'picnic'
end
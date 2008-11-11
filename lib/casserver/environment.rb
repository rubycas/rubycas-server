$: << File.dirname(File.expand_path(__FILE__))

# Try to load local version of Picnic if possible (for development purposes)
alt_picic_paths = []
alt_picic_paths << File.dirname(File.expand_path(__FILE__))+"/../../../picnic/lib"
alt_picic_paths << File.dirname(File.expand_path(__FILE__))+"/../../vendor/picnic/lib"

begin
  require 'active_record'
rescue LoadError
  require 'rubygems'
  require 'active_record'
end

if alt_picic_paths.any?{|path| File.exists? "#{path}/picnic.rb" }
  alt_picic_paths.each{|path| $: << path}
  require 'picnic'
else
  require 'rubygems'
  
  # make things backwards-compatible for rubygems < 0.9.0
  if respond_to?(:require_gem)
    puts "WARNING: aliasing gem to require_gem in #{__FILE__} -- you should update your RubyGems system!"
    alias gem require_gem
  end
 
  require 'picnic'
end

# used for serializing user extra_attributes (see #service_validate in views.rb)
require 'yaml'

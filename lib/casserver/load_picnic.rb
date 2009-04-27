if File.exists?(picnic = File.expand_path(File.dirname(File.expand_path(__FILE__))+'/../../vendor/picnic/lib'))
  puts "Loading picnic from #{picnic.inspect}..."
  $: << picnic
elsif File.exists?(picnic = File.expand_path(File.dirname(File.expand_path(__FILE__))+'/../../../picnic/lib'))
  puts "Loading picnic from #{picnic.inspect}..."
  $: << picnic
else
  puts "Loading picnic from rubygems..."
  require 'rubygems'
  
  begin
    # Try to load dev version of picnic if available (for example 'zuk-picnic' from Github)
    gem /^.*?-picnic$/
  rescue Gem::LoadError
    gem 'picnic'
  end
end



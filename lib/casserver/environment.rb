$: << File.dirname(File.expand_path(__FILE__))

# Try to load local version of Picnic if possible...
$: << File.dirname(File.expand_path(__FILE__))+"/../../../picnic/lib"
$: << File.dirname(File.expand_path(__FILE__))+"/../../vendor/picnic/lib"

require 'rubygems'

# make things backwards-compatible for rubygems < 0.9.0
unless Object.method_defined? :gem
  alias gem require_gem
end

require 'picnic'
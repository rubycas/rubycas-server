require 'casserver/core_ext/string'

# We only need to modify securerandom if we're using
# ActiveSupport's implementation.
if RUBY_VERSION < "1.9"
  require 'securerandom'
  require 'casserver/core_ext/securerandom'

  SecureRandom.send(:include, CASServer::CoreExt::SecureRandom)
end

String.send(:include, CASServer::CoreExt::String)

require 'securerandom'

module CASServer::CoreExt
  module SecureRandom
    # This is a copypaste job from 1.9.3, ActiveSupport
    # doesn't come with this method and it is an easier
    # way to get a random string that's good for tickets.
    # Less code to maintain means less things we can break.
    def self.urlsafe_base64(n=nil, padding=false)
      s = [::SecureRandom.random_bytes(n)].pack("m*")
      s.delete!("\n")
      s.tr!("+/","-_")
      s.delete!("=") if !padding
      s
    end
  end
end

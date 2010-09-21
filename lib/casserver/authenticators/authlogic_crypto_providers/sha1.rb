require "digest/sha1"

module Authlogic
  module CryptoProviders
    # This class was made for the users transitioning from restful_authentication.
    # I highly discourage using this crypto provider as it inferior to your other options.
    # Please use any other provider offered by Authlogic.
    class Sha1
      class << self
        def join_token
          @join_token ||= "--"
        end
        attr_writer :join_token

        def digest_format=(format)
          @digest_format = format
        end

        # This is for "old style" authentication with a custom format of digest
        def digest(tokens)
          if @digest_format
            @digest_format.
              gsub('PASSWORD', tokens.first).
              gsub('SALT', tokens.last)
          else
            tokens.join(join_token)
          end
        end

        # The number of times to loop through the encryption.
        # This is ten because that is what restful_authentication defaults to.

        def stretches
          @stretches ||= 10
        end
        attr_writer :stretches

        # Turns your raw password into a Sha1 hash.
        def encrypt(*tokens)
          tokens = tokens.flatten

          if stretches > 1
            hash = tokens.shift
            stretches.times { hash = Digest::SHA1.hexdigest([hash, *tokens].join(join_token)) }
          else
            hash = Digest::SHA1.hexdigest( digest(tokens) )
          end

          hash
        end

        # Does the crypted password match the tokens? Uses the same tokens that were used to encrypt.
        def matches?(crypted, *tokens)
          encrypt(*tokens) == crypted
        end
      end
    end
  end
end

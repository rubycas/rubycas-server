require 'casserver/authenticators/sql'

require 'digest/md5'

# Essentially the same as the standard SQL authenticator, but this version
# assumes that your password is stored as an MD5 hash.
#
# This was contributed by malcomm for Drupal authentication. To work with
# Drupal, you should use 'name' for the :username_column config option, and
# 'pass' for the :password_column.
class CASServer::Authenticators::SQLMd5 < CASServer::Authenticators::SQL

  protected
    def read_standard_credentials(credentials)
      super
      @password = Digest::MD5.hexdigest(@password)
    end

end

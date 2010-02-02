require 'casserver/authenticators/base'

# NOT YET IMPLEMENTED
#
# This authenticator will authenticate the user based on a client SSL certificate.
#
# You will probably want to use this along with another authenticator, chaining
# it so that if the client does not provide a certificate, the server can
# fall back to some other authentication mechanism.
#
# Here's an example of how to use two chained authenticators in the config.yml
# file. The server will first use the ClientCertificate authenticator, and
# only fall back to the SQL authenticator of the first one fails:
#
# authenticator:
#  -
#    class: CASServer::Authenticators::ClientCertificate
#  -
#    class: CASServer::Authenticators::SQL
#    database:
#      adapter: mysql
#      database: some_database_with_users_table
#      user: root
#      password:
#      server: localhost
#    user_table: user
#    username_column: username
#    password_column: password
#
class CASServer::Authenticators::ClientCertificate < CASServer::Authenticators::Base
  def validate(credentials)
    read_standard_credentials(credentials)

    @client_cert = credentials[:request]['SSL_CLIENT_CERT']

    # note that I haven't actually tested to see if SSL_CLIENT_CERT gets
    # filled with data when a client cert is provided, but this should be
    # the case at least in theory :)

    return false if @client_cert.blank?

    # IMPLEMENT SSL CERTIFICATE VALIDATION CODE HERE
    raise NotImplementedError, "#{self.class.name}#validate NOT YET IMPLEMENTED!"

    return true # if SSL certificate is valid, false otherwise
  end
end

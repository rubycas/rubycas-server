require 'active_record'
require 'active_support'
require 'builder' # for XML views

require 'casserver/authenticators/base'
require 'casserver/server'

CASServer::Authenticators.autoload :LDAP, 'casserver/authenticators/ldap.rb'
CASServer::Authenticators.autoload :ActiveDirectoryLDAP, 'casserver/authenticators/active_directory_ldap/'
CASServer::Authenticators.autoload :SQL, 'casserver/authenticators/sql.rb'
CASServer::Authenticators.autoload :Google, 'casserver/authenticators/google.rb'
CASServer::Authenticators.autoload :SQLEncrypted, 'casserver/authenticators/sql_encrypted.rb'
CASServer::Authenticators.autoload :ActiveResource, 'casserver/authenticators/active_resource.rb'
CASServer::Authenticators.autoload :Test, 'casserver/authenticators/test.rb'

require 'casserver/server'

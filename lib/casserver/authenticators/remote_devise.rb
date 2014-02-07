require 'casserver/authenticators/base'
require 'uri'
require 'net/http'
require 'net/https'
require 'timeout'
require 'json'

# Validates accounts against a remote Devise installation using its JSON API.
#
# For example:
#
#   authenticator:
#     class: CASServer::Authenticators::RemoteDevise
#     url: https://devise.url/users/sign_in.json
#     devise:
#       model: user
#       attribute: username
#     timeout: 10
#     proxy:
#       host:
#       port:
#       username:
#       password:
#
# Definitions:
#   url -- The URL (ending in .json) of the page that login information is POSTed to.
#   model -- The lowercase name of the model being authenticated. Defaults to 'user'.
#   attribute -- The name of the attribute used as the username. Defaults to 'email'.
#   timeout -- Number of seconds to wait for response from Devise. Defaults to 10 seconds.
#
# All user account attributes returned by API on successful auth are available as extra attributes.
# To avoid conflicts, if a :username attribute is provided to the extra attributes, it will be renamed to
# :username_devise.
class CASServer::Authenticators::RemoteDevise < CASServer::Authenticators::Base
  def self.setup(options)
    raise CASServer::AuthenticatorError, "No Devise URL provided" unless options[:url]

    (options[:devise] ||= {})[:model] = options[:devise][:model] || 'user'
    (options[:devise] ||= {})[:attribute] = options[:devise][:attribute] || 'email'
    options[:timeout] = options[:timeout] || 10
  end

  def validate(credentials)
    read_standard_credentials(credentials)

    return false if @username.blank? || @password.blank?

    auth_data = {
      "#{@options[:devise][:model]}" => {      
        "#{@options[:devise][:attribute]}" => @username,
        "password"                         => @password,
      },
    }

    url = URI.parse(@options[:url])
    if @options[:proxy]
      http = Net::HTTP.Proxy(@options[:proxy][:host], @options[:proxy][:port], @options[:proxy][:username], @options[:proxy][:password]).new(url.host, url.port)
    else
      http = Net::HTTP.new(url.host, url.port)
    end

    http.use_ssl = (url.scheme == "https")

    begin
      timeout(@options[:timeout]) do
        begin
          res = http.start do |conn|
            req = Net::HTTP::Post.new(url.path)
            req.body = JSON.generate(auth_data)
            req['Accept'] = 'application/json'
            req['Content-Type'] = 'application/json'
            conn.request(req)
          end
        rescue StandardError => e
          raise CASServer::AuthenticatorError, "Login server currently unavailable. (Connection Error: #{e.to_s})"
        end

        case res
        when Net::HTTPNotAcceptable
          $LOG.error("Devise said it couldn't return JSON (HTTP error 406). This could also be a problem with CSRF being enabled.")
          raise CASServer::AuthenticatorError, "Login server currently unavailable. (Could not supply requested data format)"

        when Net::HTTPSuccess, Net::HTTPUnauthorized

          content_type = res['content-type'].split(';')[0]
          if content_type != 'application/json'
            $LOG.error("Devise didn't return application/json content-type. Instead; #{content_type}")
            raise CASServer::AuthenticatorError, "Login server currently unavailable. (Returned Content-Type not application/json)"
          end

          begin
            json = ActiveSupport::JSON.decode(res.body)
          rescue StandardError => e
            $LOG.error("Unable to decode Devise JSON response. Exception: #{e}")
            raise CASServer::AuthenticatorError, "Login server currently unavailable. (Unable to decode JSON response)"
          end

          if json.has_key? 'error'
            raise CASServer::AuthenticatorError, json['error'] # Devise auth rejection message
          end

          @extra_attributes = json[@options[:devise][:model].to_s]

          if @extra_attributes.has_key? 'username'
            @extra_attributes['username_devise'] = @extra_attributes['username']
            @extra_attributes.delete('username')
          end

          return true

        when Net::HTTPInternalServerError
          $LOG.error("Devise throws Internal Server Error while validating credentials: #{res.inspect} ==> #{res.body}.")
          raise CASServer::AuthenticatorError, "Login server currently unavailable. (Internal Server Error recieved while validating credentials)"

        else
          $LOG.error("Unexpected response code from Devise while validating credentials: #{res.inspect} ==> #{res.body}.")
          raise CASServer::AuthenticatorError, "Login server currently unavailable. (Unexpected response code received while validating credentials)"
        end
      end

    rescue Timeout::Error
      $LOG.error("Devise did not respond to the credential validation request. We waited for #{@options[:timeout]} seconds before giving up.")
      raise CASServer::AuthenticatorError, "Login server currently unavailable. (Timeout while waiting to validate credentials)"
    end

  end
end

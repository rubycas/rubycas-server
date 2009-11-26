require 'casserver/authenticators/base'
require 'activeresource'
  
require 'openssl'
require 'digest/sha2'
require 'base64'

module TaccEncryption

  KEY = Digest::SHA256.hexdigest('T4CcUs3R-C3|\|TR41A|_|Th')

  def self.encrypt(text)
    Base64.encode64(aes(:encrypt, KEY, text))
  end

  def self.decrypt(crypted_text)
    aes(:decrypt, KEY, Base64.decode64(crypted_text))
  end

  private

    def self.aes(m,k,t)
      (aes = OpenSSL::Cipher::Cipher.new('aes-256-cbc').send(m)).key = Digest::SHA256.digest(k)
      aes.update(t) << aes.final
    end

end

class TaccUser < ActiveResource::Base
  self.collection_name = 'users'
  self.timeout = 5
  
  def self.find_by_email(email)
    if u = self.find(:all, :params => { :email => email }).first
      return self.find(u.id)
    else
      return nil
    end
  end
  
  def authenticate(password)
    begin
      return true if self.put(:authenticate, :password => TaccEncryption.encrypt(password))
    rescue
      return false
    end
  end
  
end

class CASServer::Authenticators::Tacc < CASServer::Authenticators::Base

  def validate(credentials)
    raise CASServer::AuthenticatorError, "Cannot validate credentials because the authenticator hasn't been configured" unless @options
    
    TaccUser.site = @options[:site]
    
    read_standard_credentials(credentials) # Sets @username and @password
    
    @user = TaccUser.find_by_email(@username)
    raise CASServer::AuthenticatorError, "User not found" if @user.nil?
    
    return @user.authenticate(@password)
    
  end
end


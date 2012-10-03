# encoding: UTF-8
require 'spec_helper'

require 'casserver/authenticators/ldap'

describe CASServer::Authenticators::LDAP do
  before do
    if $LOG.nil?
      load_server('default_config') # a lazy way to make sure the logger is set up
    end

    @ldap_entry = mock(Net::LDAP::Entry.new)
    @ldap_entry.stub!(:[]).and_return("Test")
    
    @ldap = mock(Net::LDAP)
    @ldap.stub!(:host=)
    @ldap.stub!(:port=)
    @ldap.stub!(:encryption)
    @ldap.stub!(:bind_as).and_return(true)
    @ldap.stub!(:authenticate).and_return(true)
    @ldap.stub!(:search).and_return([@ldap_entry])
    
    Net::LDAP.stub!(:new).and_return(@ldap)
  end
  
  describe '#validate' do

    it 'validate with preauthentication and with extra attributes' do
      auth = CASServer::Authenticators::LDAP.new

      auth_config = HashWithIndifferentAccess.new(
        :ldap => {
          :host => "ad.example.net",
          :port => 389,
          :base => "dc=example,dc=net",
          :filter => "(objectClass=person)",
          :auth_user => "authenticator",
          :auth_password => "itsasecret"
        },
        :extra_attributes => [:full_name, :address]
      )
      
      auth.configure(auth_config.merge('auth_index' => 0))
      auth.validate(
        :username => 'validusername',
        :password => 'validpassword',
        :service =>  'test.service',
        :request => {}
      ).should == true
      
      auth.extra_attributes.should == {:full_name => 'Test', :address => 'Test'}
    end
    
  end
end



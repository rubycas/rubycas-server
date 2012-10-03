# encoding: UTF-8
require 'spec_helper'

require 'casserver/authenticators/active_resource'

describe CASServer::Authenticators::Helpers::Identity do

  it { should be_an ActiveResource::Base }

  it "class should respond to :authenticate" do
    subject.class.should respond_to :authenticate
  end

  it "class should have a method_name accessor" do
    CASServer::Authenticators::Helpers::Identity.method_name.should == :authenticate
  end

  it "class should have a method_name accessor" do
    CASServer::Authenticators::Helpers::Identity.method_type.should == :post
  end

  it "class method_type accessor should validate type" do
    expect {
      CASServer::Authenticators::Helpers::Identity.method_type = :foo
    }.to raise_error(ArgumentError)
  end

end

describe CASServer::Authenticators::ActiveResource do

  describe "#setup" do

    it "should configure the identity object" do
      CASServer::Authenticators::Helpers::Identity.should_receive(:user=).with('httpuser').once
      CASServer::Authenticators::ActiveResource.setup :site => 'http://api.example.org', :user => 'httpuser'
    end

    it "should configure the method_type" do
      CASServer::Authenticators::Helpers::Identity.should_receive(:method_type=).with('get').once
      CASServer::Authenticators::ActiveResource.setup :site => 'http://api.example.org', :method_type => 'get'
    end

    it "should raise if site option is missing" do
      expect {
        CASServer::Authenticators::ActiveResource.setup({}).should
      }.to raise_error(CASServer::AuthenticatorError, /site option/)
    end
  end

  describe "#validate" do

    let(:credentials) { {:username => 'validusername',
                         :password => 'validpassword',
                         :service => 'test.service'} }

    let(:auth) { CASServer::Authenticators::ActiveResource.new }

    def mock_authenticate identity = nil
      identity = CASServer::Authenticators::Helpers::Identity.new if identity.nil?
      CASServer::Authenticators::Helpers::Identity.stub!(:authenticate).and_return(identity)
    end

    def sample_identity attrs = {}
      identity = CASServer::Authenticators::Helpers::Identity.new
      attrs.each { |k,v| identity.send "#{k}=", v }
      identity
    end

    it "should call Identity#autenticate with the given params" do
      CASServer::Authenticators::Helpers::Identity.should_receive(:authenticate).with(credentials).once
      auth.validate(credentials)
    end

    it "should return identity object attributes as extra attributes" do
      auth.configure({}.with_indifferent_access)
      identity = sample_identity({:email => 'foo@example.org'})
      mock_authenticate identity
      auth.validate(credentials).should be_true
      auth.extra_attributes.should == identity.attributes
    end

    it "should return false when http raises" do
      CASServer::Authenticators::Helpers::Identity.stub!(:authenticate).and_raise(ActiveResource::ForbiddenAccess.new({}))
      auth.validate(credentials).should be_false
    end

    it "should apply extra_attribute filter" do
      auth.configure({ :extra_attributes => 'age'}.with_indifferent_access)
      mock_authenticate sample_identity({ :email => 'foo@example.org', :age => 28 })
      auth.validate(credentials).should be_true
      auth.extra_attributes.should == { "age" => "28" }
    end

    it "should only extract not filtered attributes" do
      auth.configure({ :filter_attributes => 'age'}.with_indifferent_access)
      mock_authenticate sample_identity({ :email => 'foo@example.org', :age => 28 })
      auth.validate(credentials).should be_true
      auth.extra_attributes.should == { "email" => 'foo@example.org' }
    end

    it "should filter password if filter attributes is not given" do
      auth.configure({}.with_indifferent_access)
      mock_authenticate sample_identity({ :email => 'foo@example.org', :password => 'secret' })
      auth.validate(credentials).should be_true
      auth.extra_attributes.should == { "email" => 'foo@example.org' }
    end
  end
end

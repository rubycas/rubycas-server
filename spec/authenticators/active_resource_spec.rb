# encoding: UTF-8
require File.dirname(__FILE__) + '/../spec_helper'

require 'casserver/authenticators/active_resource'

describe CASServer::Authenticators::Helpers::Identity do

  it { should be_an ActiveResource::Base }

  it { should respond_to? :autenticate }
end

describe CASServer::Authenticators::ActiveResource do

  describe "#setup" do
    it "should configure the identity object"
  end

  describe "#validate" do

    it "should raise if site option is missing"

    it "should call Identity#autenticate with the given params"

  end
end

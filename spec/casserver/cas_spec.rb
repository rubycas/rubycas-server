require 'spec_helper'

module CASServer; end
require 'casserver/cas'

describe CASServer::CAS do
  before do
    load_server
    @klass = Class.new {
      include CASServer::CAS
    }
    @client_hostname = 'myhost.test'
    @host = @klass.new
    @host.instance_variable_set(:@env, {
      'REMOTE_HOST' => @client_hostname
    })
  end

  describe "#generate_login_ticket" do
    before do
      @lt = @host.generate_login_ticket
    end

    it "should return a login ticket" do
      @lt.class.should == CASServer::Model::LoginTicket
    end

    it "should set the client_hostname" do
      @lt.client_hostname.should == @client_hostname
    end

    it "should set the ticket string" do
      @lt.ticket.should_not be_nil
    end

    it "SHOULD set the ticket string starting with 'LT'" do
      @lt.ticket.should match /^LT/
    end

    it "should not mark the ticket as consumed" do
      @lt.consumed.should be_nil
    end
  end
end

require 'rubygems'
require 'mosquito'

$CONF = {:authenticator => {:class => "CASServer::Authenticators::Test"}, 
          :log => {:file => "/tmp/test.log", :level => "INFO"}}

require File.dirname(__FILE__) + "/../lib/casserver"

CASServer.create

class TestCASServer < Camping::UnitTest

  include CASServer::CAS

  def test_generate_proxy_granting_ticket
    pgt_url = "https://portal.urbacon.net:6543/cas_proxy_callback/receive_pgt"
    st = generate_service_ticket("http://test.foo", "tester")
    
    pgt = nil
    
    assert_difference(ProxyGrantingTicket, :count, 1) do
      pgt = generate_proxy_granting_ticket(pgt_url, st)
    end
    
    puts pgt.inspect
  end
  
  protected
  def env
    return {'REMOTE_ADDR' => "TEST"}
  end

end

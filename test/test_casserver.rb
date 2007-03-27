require 'rubygems'
require 'mosquito'

$CONF = {:authenticator => {:class => "CASServer::Authenticators::Test"}}

require File.dirname(__FILE__) + "/../lib/casserver"

include CASServer::Models
CASServer.create

class TestCASServer < Camping::FunctionalTest

  def test_test_atuhenticator
    require File.dirname(__FILE__) + "/../lib/casserver/authenticators/test"
    
    valid_credentials = {:username => "testuser", :password => "testpassword"}
    invalid_credentials = {:username => "asdfsdf", :password => "asdfsdf"}
    
    assert_equal CASServer::Authenticators::Test, $AUTH.class
    assert $AUTH.validate(valid_credentials)
    assert !$AUTH.validate(invalid_credentials)
  end
  
  def test_valid_login
    lt = start_login
    
    post '/login',
          :lt => lt.ticket, 
          :username => "testuser",
          :password => "testpassword"
          
    assert_match_body("You have successfully logged in")
    
    lt = LoginTicket.find_by_ticket(lt.ticket)
    
    assert_not_nil @cookies[:tgt]
    assert_not_nil TicketGrantingTicket.find_by_ticket(@cookies[:tgt])
    
    assert lt.consumed?
  end
  
  def test_valid_login_with_service
    lt = start_login
    
    fake_service = "http://www.google.com/"
    
    post '/login',
          :lt => lt.ticket, 
          :username => "testuser",
          :password => "testpassword",
          :service => fake_service
          
    @response.headers['Location'].to_s =~ /(.*?)\?ticket=(.*)/
    redirected_to = $~[1]
    service_ticket = $~[2]
    
    assert_equal fake_service, redirected_to
    
    assert_not_nil service_ticket
    st = ServiceTicket.find_by_ticket(service_ticket)
    assert_equal fake_service, st.service
    assert_equal "testuser", st.username
    assert !st.consumed?

    assert_not_nil @cookies[:tgt]
    assert_not_nil TicketGrantingTicket.find_by_ticket(@cookies[:tgt])
    
    assert LoginTicket.find_by_ticket(lt.ticket).consumed?
  end
  
  def test_invalid_login
    lt = start_login
    
    post '/login',
          :lt => lt.ticket, 
          :username => "testuser",
          :password => "badpassword"
          
    assert_match_body("Incorrect username or password")
    
    # reusing the same login ticket should fail
    post '/login',
          :lt => lt.ticket, 
          :username => "testuser",
          :password => "testpassword"
          
    assert_match_body("The login ticket you provided has already been used up")
    
    # missing username/password
    lt = start_login
    post '/login',
          :lt => lt.ticket
          
    assert_match_body("Incorrect username or password")
    
    # missing login ticket
    post '/login',
          :username => "testuser",
          :password => "testpassword"
    
    assert_match_body("Your login request did not include a login ticket")
  end
  
  private
  def start_login
    assert_difference(LoginTicket, :count, 1) do
      get '/login'
    end
    
    assert_response :success
    assert_match_body("Login")

    @response.body =~ /LT-[a-zA-Z0-9]*/
    lt = $~[0]
    assert_not_nil lt
    
    lt = LoginTicket.find_by_ticket(lt)
    assert_not_nil lt
    
    assert !lt.consumed?
    
    lt
  end

end

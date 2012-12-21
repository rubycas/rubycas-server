# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'

$LOG = Logger.new(File.basename(__FILE__).gsub('.rb','.log'))

RSpec.configure do |config|
  config.include Capybara::DSL
end

VALID_USERNAME = 'spec_user'
VALID_PASSWORD = 'spec_password'

ATTACK_USERNAME = '%3E%22%27%3E%3Cscript%3Ealert%2826%29%3C%2Fscript%3E&password=%3E%22%27%3E%3Cscript%3Ealert%2826%29%3C%2Fscript%3E&lt=%3E%22%27%3E%3Cscript%3Ealert%2826%29%3C%2Fscript%3E&service=%3E%22%27%3E%3Cscript%3Ealert%2826%29%3C%2Fscript%3E'
INVALID_PASSWORD = 'invalid_password'

describe 'CASServer' do
  include Rack::Test::Methods

  before do
    @target_service = 'http://my.app.test'
  end

  describe "/login" do
    before do
      load_server("default_config")
      reset_spec_database
    end

    it "logs in successfully with valid username and password without a target service" do
      visit "/login"

      fill_in 'username', :with => VALID_USERNAME
      fill_in 'password', :with => VALID_PASSWORD
      click_button 'login-submit'

      page.should have_content("You have successfully logged in")
    end

    it "fails to log in with invalid password" do
      visit "/login"
      fill_in 'username', :with => VALID_USERNAME
      fill_in 'password', :with => INVALID_PASSWORD
      click_button 'login-submit'

      page.should have_content("Incorrect username or password")
    end

    it "logs in successfully with valid username and password and redirects to target service" do
      visit "/login?service="+CGI.escape(@target_service)

      fill_in 'username', :with => VALID_USERNAME
      fill_in 'password', :with => VALID_PASSWORD

      click_button 'login-submit'

      page.current_url.should =~ /^#{Regexp.escape(@target_service)}\/?\?ticket=ST\-[1-9rA-Z]+/
    end

    it "preserves target service after invalid login" do
      visit "/login?service="+CGI.escape(@target_service)

      fill_in 'username', :with => VALID_USERNAME
      fill_in 'password', :with => INVALID_PASSWORD
      click_button 'login-submit'

      page.should have_content("Incorrect username or password")
      page.should have_xpath('//input[@id="service"]', :value => @target_service)
    end

    it "uses appropriate localization based on Accept-Language header" do

      page.driver.options[:headers] = {'HTTP_ACCEPT_LANGUAGE' => 'pl'}
      #visit "/login?lang=pl"
      visit "/login"
      page.should have_content("Użytkownik")

      page.driver.options[:headers] = {'HTTP_ACCEPT_LANGUAGE' => 'pt_BR'}
      #visit "/login?lang=pt_BR"
      visit "/login"
      page.should have_content("Usuário")

      page.driver.options[:headers] = {'HTTP_ACCEPT_LANGUAGE' => 'en'}
      #visit "/login?lang=en"
      visit "/login"
      page.should have_content("Username")
    end

    it "is not vunerable to Cross Site Scripting" do
      visit '/login?service=%22%2F%3E%3cscript%3ealert%2832%29%3c%2fscript%3e'
      page.should_not have_content("alert(32)")
      page.should_not have_xpath("//script")
      #page.should have_xpath("<script>alert(32)</script>")
    end

  end # describe '/login'


  describe '/logout' do
    describe 'user logged in' do
      before do
        load_server("default_config")
        reset_spec_database
        visit "/login"
        fill_in 'username', :with => VALID_USERNAME
        fill_in 'password', :with => VALID_PASSWORD
        click_button 'login-submit'
        page.should have_content("You have successfully logged in")
      end

      it "logs out user who is looged in" do
        visit "/logout"
        page.should have_content("You have successfully logged out")
      end

      it "logs out successfully and redirects to target service" do
        visit "/logout?gateway=true&service="+CGI.escape(@target_service)

        page.current_url.should =~ /^#{Regexp.escape(@target_service)}\/?/
      end
    end

    describe "user not logged in" do
      it "try logs out user which is not logged in" do
        visit "/logout"
        page.should have_content("You have successfully logged out")
      end
    end

  end # describe '/logout'

  describe 'Configuration' do
    it "uri_path value changes prefix of routes" do
      load_server("alt_config")
      @target_service = 'http://my.app.test'

      visit "/test/login"
      page.status_code.should_not == 404

      visit "/test/logout"
      page.status_code.should_not == 404
    end
  end

  describe 'validation' do
    let(:allowed_ip) { '127.0.0.1' }
    let(:unallowed_ip) { '10.0.0.1' }
    let(:service) { @target_service }

    before do
      load_server('default_config')  # 127.0.0.0/24 is allowed here
      reset_spec_database

      ticket = get_ticket_for(service)

      Rack::Request.any_instance.stub(:ip).and_return(request_ip)
      get "/#{path}?service=#{CGI.escape(service)}&ticket=#{CGI.escape(ticket)}"
    end

    subject { last_response }

    describe 'validate' do
      let(:path) { 'validate' }

      context 'from allowed IP' do
        let(:request_ip) { allowed_ip }

        it { should be_ok }
        its(:body) { should match 'yes' }
      end

      context 'from unallowed IP' do
        let(:request_ip) { unallowed_ip }

        its(:status) { should eql 422 }
        its(:body) { should match 'no' }
      end
    end

    describe 'serviceValidate' do
      let(:path) { 'serviceValidate' }

      context 'from allowed IP' do
        let(:request_ip) { allowed_ip }

        it { should be_ok }
        its(:content_type) { should match 'text/xml' }
        its(:body) { should match /cas:authenticationSuccess/i }
        its(:body) { should match '<test_utf_string>Ютф</test_utf_string>' }
      end

      context 'from unallowed IP' do
        let(:request_ip) { unallowed_ip }

        its(:status) { should eql 422 }
        its(:content_type) { should match 'text/xml' }
        its(:body) { should match /cas:authenticationFailure.*INVALID_REQUEST/i }
      end
    end

    describe 'proxyValidate' do
      let(:path) { 'proxyValidate' }

      context 'from allowed IP' do
        let(:request_ip) { allowed_ip }

        it { should be_ok }
        its(:content_type) { should match 'text/xml' }
        its(:body) { should match /cas:authenticationSuccess/i }
      end

      context 'from unallowed IP' do
        let(:request_ip) { unallowed_ip }

        its(:status) { should eql 422 }
        its(:content_type) { should match 'text/xml' }
        its(:body) { should match /cas:authenticationFailure.*INVALID_REQUEST/i }
      end
    end
  end
end
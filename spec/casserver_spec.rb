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

    before do
      load_server("default_config")
      reset_spec_database
    end

    it "logs out successfully" do
      visit "/logout"

      page.should have_content("You have successfully logged out")
    end

    it "logs out successfully and redirects to target service" do
      visit "/logout?gateway=true&service="+CGI.escape(@target_service)

      page.current_url.should =~ /^#{Regexp.escape(@target_service)}\/?/
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

  describe "proxyValidate" do
    before do
      load_server("default_config")
      reset_spec_database

      visit "/login?service="+CGI.escape(@target_service)

      fill_in 'username', :with => VALID_USERNAME
      fill_in 'password', :with => VALID_PASSWORD

      click_button 'login-submit'

      page.current_url.should =~ /^#{Regexp.escape(@target_service)}\/?\?ticket=ST\-[1-9rA-Z]+/
      @ticket = page.current_url.match(/ticket=(.*)$/)[1]
    end

    it "should have extra attributes in proper format" do
      visit "/serviceValidate?service=#{CGI.escape(@target_service)}&ticket=#{@ticket}"

      encoded_utf_string = "&#1070;&#1090;&#1092;" # actual string is "Ютф"
      page.body.should match("<test_utf_string>#{encoded_utf_string}</test_utf_string>")
      page.body.should match("<test_numeric>123.45</test_numeric>")
      page.body.should match("<test_utf_string>&#1070;&#1090;&#1092;</test_utf_string>")
    end
  end
end

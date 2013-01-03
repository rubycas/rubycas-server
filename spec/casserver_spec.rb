# encoding: UTF-8
require 'spec_helper'
require 'cgi'

RSpec.configure do |config|
  config.include Capybara::DSL
  config.include Rack::Test::Methods
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
      load_server
      reset_spec_database
    end

    it "logs in successfully with valid username and password without a target service" do
      visit "#{app.settings.uri_path}/login"

      fill_in 'username', :with => VALID_USERNAME
      fill_in 'password', :with => VALID_PASSWORD
      click_button 'login-submit'

      page.should have_content("You have successfully logged in")
    end

    it "fails to log in with invalid password" do
      visit "#{app.settings.uri_path}/login"
      fill_in 'username', :with => VALID_USERNAME
      fill_in 'password', :with => INVALID_PASSWORD
      click_button 'login-submit'

      page.should have_content("Incorrect username or password")
    end

    it "logs in successfully with valid username and password and redirects to target service" do
      visit "#{app.settings.uri_path}/login?service="+CGI.escape(@target_service)

      fill_in 'username', :with => VALID_USERNAME
      fill_in 'password', :with => VALID_PASSWORD

      click_button 'login-submit'
      page.current_url.should =~ /^#{Regexp.escape(@target_service)}\/?\?ticket=ST\-[1-9rA-Z]+/
    end

    it "preserves target service after invalid login" do
      visit "#{app.settings.uri_path}/login?service="+CGI.escape(@target_service)

      fill_in 'username', :with => VALID_USERNAME
      fill_in 'password', :with => INVALID_PASSWORD
      click_button 'login-submit'

      page.should have_content("Incorrect username or password")
      page.should have_xpath('//input[@id="service"]', :value => @target_service)
    end

    it "uses appropriate localization based on Accept-Language header" do

      page.driver.options[:headers] = {'HTTP_ACCEPT_LANGUAGE' => 'pl'}
      visit "#{app.settings.uri_path}/login"
      page.should have_content("Użytkownik")
      # Reset header
      page.driver.options[:headers] = {'HTTP_ACCEPT_LANGUAGE' => ''}
    end

    it "uses appropriate localization when 'locale' prameter is given" do
      visit "#{app.settings.uri_path}/login?locale=pl"
      page.should have_content("Użytkownik")

      visit "#{app.settings.uri_path}/login?locale=pt_BR"
      page.should have_content("Usuário")

      visit "#{app.settings.uri_path}/login?locale=en"
      page.should have_content("Username")
    end

    it "is not vunerable to Cross Site Scripting" do
      visit "#{app.settings.uri_path}/login?service=%22%2F%3E%3cscript%3ealert%2832%29%3c%2fscript%3e"
      page.should_not have_content("alert(32)")
      page.should_not have_xpath("//script")
    end

  end # describe '/login'


  describe '/logout' do
    describe 'user logged in' do
      before do
        load_server
        reset_spec_database
        visit "#{app.settings.uri_path}/login"
        fill_in 'username', :with => VALID_USERNAME
        fill_in 'password', :with => VALID_PASSWORD
        click_button 'login-submit'
        page.should have_content("You have successfully logged in")
      end

      it "logs out user who is looged in" do
        visit "#{app.settings.uri_path}/logout"
        page.should have_content("You have successfully logged out")
      end

      it "logs out successfully and redirects to target service" do
        visit "#{app.settings.uri_path}/logout?gateway=true&service="+CGI.escape(@target_service)

        page.current_url.should =~ /^#{Regexp.escape(@target_service)}\/?/
      end

    end

    describe "with different uri_path" do
      before do
        load_server("spec/config/alt_config.yml")
        reset_spec_database
        visit "#{app.settings.uri_path}/login"
        fill_in 'username', :with => VALID_USERNAME
        fill_in 'password', :with => VALID_PASSWORD
        click_button 'login-submit'
        page.should have_content("You have successfully logged in")
      end

      it "logs out with different uri_path" do
        visit "#{app.settings.uri_path}/login"
        page.status_code.should_not == 404

        visit "/test/logout"
        page.status_code.should_not == 404
      end

    end

    describe "user not logged in" do
      it "try logs out user which is not logged in" do
        visit "#{app.settings.uri_path}/logout"
        page.should have_content("You have successfully logged out")
      end
    end

  end # describe '/logout'

  describe "proxyValidate" do
    before do
      load_server
      reset_spec_database

      visit "#{app.settings.uri_path}/login?service="+CGI.escape(@target_service)

      fill_in 'username', :with => VALID_USERNAME
      fill_in 'password', :with => VALID_PASSWORD

      click_button 'login-submit'

      page.current_url.should =~ /^#{Regexp.escape(@target_service)}\/?\?ticket=ST\-[1-9rA-Z]+/
      @ticket = page.current_url.match(/ticket=(.*)$/)[1]
    end

    it "should have extra attributes in proper format" do
      get "#{app.settings.uri_path}/serviceValidate?service=#{CGI.escape(@target_service)}&ticket=#{@ticket}"

      last_response.content_type.should match 'text/xml'
      last_response.body.should match "<test_utf_string>Ютф</test_utf_string>"
    end
  end
end

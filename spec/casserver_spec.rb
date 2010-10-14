require File.dirname(__FILE__) + '/spec_helper'

require 'capybara'
require 'capybara/dsl'

$LOG = Logger.new(File.basename(__FILE__).gsub('.rb','.log'))

include Capybara

VALID_USERNAME = 'spec_user'
VALID_PASSWORD = 'spec_password'

INVALID_PASSWORD = 'invalid_password'

describe 'CASServer' do
  
  before do
    @target_service = 'http://my.app.test'
  end

  describe "/login" do
    before do
      load_server(File.dirname(__FILE__) + "/default_config.yml")
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

      page.current_url.should =~ /^#{Regexp.escape(@target_service)}\/\?ticket=ST\-[1-9A-Z]+/
    end

    it "preserves target service after invalid login" do
      visit "/login?service="+CGI.escape(@target_service)

      fill_in 'username', :with => VALID_USERNAME
      fill_in 'password', :with => INVALID_PASSWORD
      click_button 'login-submit'

      page.should have_content("Incorrect username or password")
      page.should have_xpath('//input[@id="service"]', :value => @target_service)
    end

  end # describe '/login'


  describe '/logout' do

    before do
      load_server(File.dirname(__FILE__) + "/default_config.yml")
      reset_spec_database
    end

    it "logs out successfully" do
      # capybara doesn't let us post directly :(
      #Capybara.current_session.driver.post '/logout'
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
      load_server(File.dirname(__FILE__) + "/alt_config.yml")
      @target_service = 'http://my.app.test'
      
      visit "/test/login"
      page.status_code.should_not == 404
      
      visit "/test/logout"
      page.status_code.should_not == 404
    end
  end
end

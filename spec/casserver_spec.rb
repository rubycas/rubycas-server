require File.dirname(__FILE__) + '/spec_helper'

$LOG = Logger.new(File.basename(__FILE__).gsub('.rb','.log'))

RSpec.configure do |config|
  config.include Capybara
end

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

    it "uses appropriate localization when 'lang' prameter is given" do
      visit "/login?lang=pl"
      page.should have_content("Użytkownik")

      visit "/login?lang=pt_BR"
      page.should have_content("Usuário")

      visit "/login?lang=en"
      page.should have_content("Username")
    end

  end # describe '/login'


  describe '/logout' do

    before do
      load_server(File.dirname(__FILE__) + "/default_config.yml")
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
      load_server(File.dirname(__FILE__) + "/alt_config.yml")
      @target_service = 'http://my.app.test'
      
      visit "/test/login"
      page.status_code.should_not == 404
      
      visit "/test/logout"
      page.status_code.should_not == 404
    end
  end

  describe "proxyValidate" do
    before do
      load_server(File.dirname(__FILE__) + "/default_config.yml")
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

      puts page.body
      page.body.should match("<test_string>testing!</test_string>")
      page.body.should match("<test_numeric>123.45</test_numeric>")
      page.body.should match("<test_utf_string>&#1070;&#1090;&#1092;</test_utf_string>")
    end
  end
end

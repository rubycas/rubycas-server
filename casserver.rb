require 'camping'
require 'camping/db'

Camping.goes :CASServer

# enable xhtml source code indentation for debugging views
Markaby::Builder.set(:indent, 2)

module CASServer
end

module CASServer::Models
  class CreateConfig < V 0.1
    def self.up
      create_table :config, :force => true do |t|
        t.column :id,     :integer, :null => false
        t.column :key,    :string, :limit => 255, :null => false
        t.column :value,  :string,  :limit => 255
      end
    end
  end
end

module CASServer::Controllers
  class Login < R '/'
    def get
      @server = "URBACON"
      render :login
    end
  end
end

module CASServer::Views
  def layout  
  @indent = 1
    xhtml_strict do
      head do 
        title { @server }
      end
      body(:onload => "if (document.getElementById('username')) document.getElementById('username').focus()") do
        self << yield 
      end
    end
  end

  def login
    table(:id => "login-box") do
      tr do
        td(:colspan => 2) do
          div(:id => "headline-container") do
            strong "URBACON"
            text "Central Login"
          end
        end
      end
      tr do
        td(:colspan => 2, :id => "messagebox-container") do
          div(:class => "messagebox confirmation") { "Test." }
        end
      end
      tr do
        td(:id => "logo-container") do
          img(:id => "logo", :src => "https://login.urbacon.net:8181/cas/themes/default/urbacon.png", :width => "115", :height => "171")
        end
        td(:id => "login-form_container") do
          form(:method => "post", :action => "", :id => "login-form",
              :onsubmit => "submit = document.getElementById('login-submit'); submit.value='Please wait...'; submit.disabled=true; return true;") do
            table(:id => "form-layout") do
              tr do
                td(:id => "username-label-container") do
                  label(:id => "username-label", :for => "username") { "Username" }
                end
                td(:id => "username-container") do
                  input(:type => "text", :id => "username", :name => "username", :size => "32", :tabindex => "1", :accesskey => "n")
                end
              end
              tr do
                td(:id => "password-label-container") do
                  label(:id => "password-label", :for => "password") { "Password" }
                end
                td(:id => "password-container") do
                  input(:type => "password", :id => "password", :name => "password", :size => "32", :tabindex => "2", :accesskey => "p")
                end
              end
              tr do
                td
                td(:id => "submit-container") do
                  input(:type => "submit", :class => "button", :accesskey => "l", :value => "LOGIN", :tabindex => "4", :id => "login-submit")
                end
              end
              tr do
                td(:colspan => 2, :id => "infoline") { "&copy Urbacon Limited 2006, All Rights Reserved" }
              end
            end
          end
        end
      end
    end
  end
  
  def configure
  end
end


def CASServer.create
  CASServer::Models.create_schema
end
require 'camping'

Camping.goes :CASServer

# enable xhtml source code indentation for debugging views
Markaby::Builder.set(:indent, 2)

module CASServer
end

# The #.#.# comments (e.g. 2.1.3) refer to section numbers in the CAS protocol spec
# under http://www.ja-sig.org/products/cas/overview/protocol/index.html

module CASServer::Controllers

  # 2.1
  class Login < R '/', '/login'
    # 2.1.1
    def get
      # optional
      @service = @input['service']
      @renew = @input['renew']
      @gateway = @input['gateway']
      
      # 3.5 (login ticket)
      @lt = "LT-#{Time.now.to_i}r%X" % rand(99999999)
      
      render :login
    end
    
    # 2.2
    def post
      # 2.2.1 (optional)
      @service = @input['service']
      @warn = @input['warn']
      
      # 2.2.2 (required)
      @username = @input['username']
      @password = @input['password']
      @lt = @input['lt']
      
      render :login
    end
  end
  
  # 2.3
  class Logout < R '/logout'
    # 2.3.1
    def get
      @url = @input['url']
      
      render :logout
    end
  end

  # 2.4
  class Validate < R '/validate'
    # 2.4.1
    def get
      # required
      @service = @input['service']
      @ticket = @input['ticket']
      # optional
      @renew = @input['renew']
      
      render :validate
    end
  end
  
  # 2.5
  class ServiceValidate < R '/serviceValidate'
    # 2.5.1
    def get
      # required
      @service = @input['service']
      @ticket = @input['ticket']
      # optional
      @pgt_url = @input['pgtUrl']
      @renew = @input['renew']
      
      render :service_validate
    end
  end
  
  # 2.6
  class ProxyValidate < R '/proxyValidate'
    # 2.6.1
    def get
      # required
      @service = @input['service']
      @ticket = @input['ticket']
      # optional
      @pgt_url = @input['pgtUrl']
      @renew = @input['renew']
      
      render :proxy_validate
    end
  end
  
  class Proxy < R '/proxy'
    # 2.7
    def get
      # required
      @pgt = @input['pgt']
      @target_service = @input['targetService']
      
      render :proxy
    end
  end
  
  class Static < R '/static/(.+)'         
    MIME_TYPES = {'.css' => 'text/css', '.js' => 'text/javascript', 
                  '.jpg' => 'image/jpeg'}
    PATH = File.expand_path(File.dirname(__FILE__))

    def get(path)
      @headers['Content-Type'] = MIME_TYPES[path[/\.\w+$/, 0]] || "text/plain"
      unless path.include? ".." # prevent directory traversal attacks
        @headers['X-Sendfile'] = "#{PATH}/static/#{path}"
      else
        @status = "403"
        "403 - Invalid path"
      end
    end
  end
end

module CASServer::Views
  def layout
    xhtml_strict do
      head do 
        title { @server }
        link(:rel => "stylesheet", :type => "text/css", :href => "static/cas.css")
      end
      body(:onload => "if (document.getElementById('username')) document.getElementById('username').focus()") do
        self << yield 
      end
    end
  end

  # 2.1.3
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
                td{}
                td(:id => "submit-container") do
                  input(:type => "hidden", :id => "lt", :name => "lt", :value => @lt)
                  input(:type => "hidden", :id => "service", :name => "service", :value => @service)
                  input(:type => "hidden", :id => "warn", :name => "warn", :value => @warn)
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
  
  # 2.4.2
  def validate
    if @success
      text "yes\n#{@username}\n"
    else
      text "no\n\n"
    end
  end
  
  # 2.5.2
  def service_validate
    if @success
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationSuccess") do
          tag!("cas:user") {@username}
          tag!("cas:proxyGrantingTicket") {@pgt}
        end
      end
    else
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationFailure", :code => @error.code) {@error}
      end
    end
  end
  
  # 2.6.2
  def proxy_validate
    if @success
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationSuccess") do
          tag!("cas:user") {@username}
          tag!("cas:proxyGrantingTicket") {@pgt}
          tag!("cas:proxies") do
            @proxies.each do |proxy_url|
              tag!("cas:proxy") {proxy_url}
            end
          end
        end
      end
    else
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationFailure", :code => @error.code) {@error}
      end
    end
  end
  
  # 2.7.2
  def proxy
    if @success
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:proxySuccess") do
          tag!("cas:proxyTicket") {@pt}
        end
      end
    else
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:proxyFailure", :code => @error.code) {@error}
      end
    end
  end
  
  def configure
  end
end


def CASServer.create
end
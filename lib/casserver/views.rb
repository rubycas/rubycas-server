# The #.#.# comments (e.g. "2.1.3") refer to section numbers in the CAS protocol spec
# under http://www.ja-sig.org/products/cas/overview/protocol/index.html

# need auto_validation off to render CAS responses and to use the autocomplete='off' property on password field
Markaby::Builder.set(:auto_validation, false)

# disabled XML indentation because it was causing problems with mod_auth_cas
#Markaby::Builder.set(:indent, 2) 

module CASServer::Views

  def layout
    # wrap as XHTML only when auto_validation is on, otherwise pass right through
    if @use_layout
      xhtml_strict do
        head do 
          title { "#{organization} Central Login" }
          link(:rel => "stylesheet", :type => "text/css", :href => "/themes/cas.css")
          link(:rel => "stylesheet", :type => "text/css", :href => "/themes/#{current_theme}/theme.css")
        end
        body(:onload => "if (document.getElementById('username')) document.getElementById('username').focus()") do
          self << yield 
        end
      end
    else
      self << yield
    end
  end


  # 2.1.3
  # The full login page.
  def login
    @use_layout = true
    
    table(:id => "login-box") do
      tr do
        td(:colspan => 2) do
          div(:id => "headline-container") do
            strong organization
            text " Central Login"
          end
        end
      end
      if @message
        tr do
          td(:colspan => 2, :id => "messagebox-container") do
            div(:class => "messagebox #{@message[:type]}") { @message[:message] }
          end
        end
      end
      tr do
        td(:id => "logo-container") do
          img(:id => "logo", :src => "/themes/#{current_theme}/logo.png")
        end
        td(:id => "login-form-container") do
          @include_infoline = true
          login_form
        end
      end
    end
  end
  
  # Just the login form.
  def login_form
    form(:method => "post", :action => @form_action || '/login', :id => "login-form",
        :onsubmit => "submitbutton = document.getElementById('login-submit'); submitbutton.value='Please wait...'; submitbutton.disabled=true; return true;") do
      table(:id => "form-layout") do
        tr do
          td(:id => "username-label-container") do
            label(:id => "username-label", :for => "username") { "Username" }
          end
          td(:id => "username-container") do
            input(:type => "text", :id => "username", :name => "username",
              :size => "32", :tabindex => "1", :accesskey => "u")
          end
        end
        tr do
          td(:id => "password-label-container") do
            label(:id => "password-label", :for => "password") { "Password" }
          end
          td(:id => "password-container") do
            input(:type => "password", :id => "password", :name => "password", 
              :size => "32", :tabindex => "2", :accesskey => "p", :autocomplete => "off")
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
          td(:colspan => 2, :id => "infoline") { infoline }
        end if @include_infoline
      end
    end
  end
  
  # 2.3.2
  def logout
    @use_layout = true
    
    table(:id => "login-box") do
      tr do
        td(:colspan => 2) do
          div(:id => "headline-container") do
            strong organization
            text " Central Login"
          end
        end
      end
      if @message
        tr do
          td(:colspan => 2, :id => "messagebox-container") do
            div(:class => "messagebox #{@message[:type]}") { @message[:message] }
            if @continue_url
              p do
                a(:href => @continue_url) { @continue_url }
              end
            end
          end
        end
      end
    end
  end
  
  # 2.4.2
  # CAS 1.0 validate response.
  def validate
    if @success
      text "yes\n#{@username}\n"
    else
      text "no\n\n"
    end
  end
  
  # 2.5.2
  # CAS 2.0 service validate response.
  def service_validate
    if @success
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationSuccess") do
          tag!("cas:user") {@username.to_s.to_xs}
          @extra_attributes.each do |key, value|
            tag!(key) {value}
          end
          if @pgtiou
            tag!("cas:proxyGrantingTicket") {@pgtiou.to_s.to_xs}
          end
        end
      end
    else
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationFailure", :code => @error.code) {@error.to_s.to_xs}
      end
    end
  end
  
  # 2.6.2
  # CAS 2.0 proxy validate response.
  def proxy_validate
    if @success
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationSuccess") do
          tag!("cas:user") {@username.to_s.to_xs}
          @extra_attributes.each do |key, value|
            tag!(key) {value}
          end
          if @pgtiou
            tag!("cas:proxyGrantingTicket") {@pgtiou.to_s.to_xs}
          end
          if @proxies && !@proxies.empty?
            tag!("cas:proxies") do
              @proxies.each do |proxy_url|
                tag!("cas:proxy") {proxy_url.to_s.to_xs}
              end
            end
          end
        end
      end
    else
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:authenticationFailure", :code => @error.code) {@error.to_s.to_xs}
      end
    end
  end
  
  # 2.7.2
  # CAS 2.0 proxy request response.
  def proxy
    if @success
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:proxySuccess") do
          tag!("cas:proxyTicket") {@pt.to_s.to_xs}
        end
      end
    else
      tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
        tag!("cas:proxyFailure", :code => @error.code) {@error.to_s.to_xs}
      end
    end
  end
  
  def configure
  end
  
  protected
  def themes_dir
    File.dirname(File.expand_path(__FILE__))+'../themes'
  end
  module_function :themes_dir
  
  def current_theme
    CASServer::Conf.theme || "simple"
  end
  module_function :current_theme
  
  def organization
    CASServer::Conf.organization || ""
  end
  module_function :organization
  
  def infoline
    CASServer::Conf.infoline || ""
  end
  module_function :infoline
end

if CASServer::Conf.custom_views_file
  require CASServer::Conf.custom_views_file
end

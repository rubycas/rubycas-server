#!/usr/bin/env ruby

$:.unshift File.dirname(__FILE__) + "/../../lib"
require 'camping'
require 'camping/db'
require 'camping/session'
  
Camping.goes :Setup

module Setup
  include Camping::Session
end

module Setup::Controllers
  
  class Index < R '/'
    def get
      render :index
    end
  end
  
  # Renders static pages from the ./static directory
  #
  class Static < R '/static/(.+)'     
    MIME_TYPES = {'.css' => 'text/css', '.js' => 'text/javascript', 
            '.jpg' => 'image/jpeg','.png' => 'image/png'}
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

  class Style < R '/styles.css'
    def get
      @headers["Content-Type"] = "text/css; charset=utf-8"
      @body = %{
        body {
          font-family: Utopia, Georga, serif;
        }
        h1.header {
          background-color: #fef;
          margin: 0; padding: 10px;
        }
        div.content {
          padding: 10px;
        }
        .page{
          position: absolute;
          top: 70;
          left: 100;
          visibility: hidden;
          text-align: right;
        }
        .tooltip {
          border:1px solid #000;
          background-color:#fff;
          width:200px;
          font-family:"Lucida Grande",Verdana;
          font-size:10px;
          color:#333;
        }
      }
    end
  end
  
  class JavaScript < R '/javascript.js'
    def get
      @headers["Content-Type"] = "text/javascript; charset=utf-8"
      @body = %{        
        var currentLayer = 'web_server_select';
         
        function showLayer(lyr){
          hideLayer(currentLayer);
          document.getElementById(lyr).style.visibility = 'visible';
          currentLayer = lyr;
        };

        function hideLayer(lyr){
          document.getElementById(lyr).style.visibility = 'hidden';
        };
        
        /*
         * Displays the results of the form. This is a debug only function.
         * It will not be used in production
         */
        function showValues(form){
          var values = '';
          var len = form.length - 1; //Leave off Submit Button
          for(i=0; i<len; i++){
            if(form[i].id.indexOf("C")!=-1||form[i].id.indexOf("B")!=-1)//Skip Continue and Back Buttons
              continue;
            if(form[i].id.indexOf("R")!=-1&&!form[i].checked)//Skip unchecked radio Back Buttons
              continue;
            if(form[i].id.indexOf("O")!=-1) //If other jump to the next box
              i++;
            values += form[i].name;
            values += ': ';
            values += form[i].value;
            values += '\\n';
          }
          alert(values);
        };        
        
        /*
         * For a given radio name return the checked button value
         */
        function getRadioValue(radio_name) {
          var radio = document.forms['rubycas_form'].elements[radio_name]
          for (var i=0; i < radio.length; i++)
             if (radio[i].checked)
             return radio[i].value;
          
        };
        
        // Wait for DOM to load 
        document.observe('dom:loaded',function(){
          // Hide the other text box.
          // TODO Maybe change this to use a css class name not the ID so we can
          // hide many at once if needed
          $('T_othersqltext').hide();
          
          //Show the other box if other is selected.
          //TODO change observed event click only works once...
          Event.observe($('O_othersql'),'click',function(){$('T_othersqltext').toggle();});
        });
      }
    end
  end
end

module Setup::Views

  def layout
    html do
      head do
        title 'RubyCAS Server Configuration'
        link :rel => 'stylesheet', :type => 'text/css', :href => '/styles.css'
        script :type => 'text/javascript', :src => '/static/prototype.js'
        script :type => 'text/javascript', :src => '/static/livepipe.js'
        script :type => 'text/javascript', :src => '/static/window.js'       
        script :type => 'text/javascript', :src => '/javascript.js'        
      end
      body do
        self << yield
      end
    end
  end

  def index  
    form(:id => "rubycas_form", :method => "POST", :action => "javascript:void(0)", :onSubmit => "showValues(this)") {
      h2 { "Welcome to RubyCAS-Server configuration." }
      text "This is a step by step process for configuring you CAS server."
      web_server_select
      webrick_config
      mongrel_config
      database_select
      mysql_config
      sqlite_config
      page3
    }
  end
  
  # Web Server Selection Page
  #
  def web_server_select
    div(:id => "web_server_select", :class => "page", :style => "visibility:visible;") {
      h3 { "Step 1. Select the web server to use." }
      
      text "Webrick" 
      input(:type => "radio", :id => 'R_webrick', :name => "webserver", :value => "webrick", :checked => true) 
      help("run as a stand-alone webrick server; this is the default method.")
      br
      
      text "Mongrel" 
      input(:type => "radio", :id => 'R_mongrel', :name => "webserver", :value => "mongrel") 
      help("run as a stand-alone mongrel server; fast, but you'll need to install mongrel and run it behind an https reverse proxy like Pound or Apache 2.2's mod_proxy). <p>IMPORTANT: If you use mongrel, you will need to run the server behind a reverse proxy (Pound, Apache 2.2 with mod_proxy, etc.) since mongrel does not support SSL/HTTPS. See the RubyCAS-Server install docs for more info.")
      br
      
      text "CGI" 
      input(:type => "radio", :id => 'R_cgi', :name => "webserver", :value => "cgi") 
      help("slow, but simple to set up if you're already familiar with deploying CGI scripts")
      br
    
      text "fastCGI" 
      input(:type => "radio", :id => 'R_fastcgi', :name => "webserver", :value => "fastcgi") 
      help("see http://www.fastcgi.com (e.g. under Apache you can use this with mod_fastcgi)")
    
      p { 
        input(:type => "button", 
          :id => "C_web_server_select", 
          :value => "Continue", 
          :onClick => "showLayer(getRadioValue('webserver'));") 
      }
    }
  end

  # Webrick Configuration page
  #
  def webrick_config  
    div(:id => "webrick", :class => "page") {
      h3 { "Step 1a. Enter the web server's details" } 
      
      text "port" 
      input(:type => "text", :id => "T_wb_port", :name => 'wb_port', :size => "20", :value => '443') 
      br
      
      text "SSL Cert" 
      input(:type => "text", :id => "T_wb_ssl_cert", :name => 'wb_ssl_cert', :size => "20") 
      help(" /path/to/your/ssl.pem")
      br
      
      text "SSL Key" 
      input(:type => "text", :id => "T_wb_ssl_key", :name => 'wb_ssl_key', :size => "20") 
      help("OPTIONAL: If private key is separate from cert")
      br
      
      text "URI Path" 
      input(:type => "text", :id => "T_wb_uri_path", :name => 'wb_uri_path', :size => "20") 
      help("OPTIONAL: By default the login page will be available at the root path (e.g. https://example.foo/). The uri_path option lets you serve it from a different path (e.g. https://example.foo/cas). uri_path: /cas")
      br
      
      text "Bind address" 
      input(:type => "text", :id => "T_wb_bind_addr", :name => 'wb_bind_addr', :size => "20") 
      help("OPTIONAL: Bind the server to a specific address. Use 0.0.0.0 to listen on all available interfaces.")
      
      p { 
        input(:type => "button", :id => "B_webrick_config", :value => "Go Back", :onClick => "showLayer('web_server_select')")
        input(:type => "button", :id => "C_webrick_config", :value => "Continue", :onClick => "showLayer('database_select')") 
      }
    }
  end

  # Mongrel Configuration Page
  #
  def mongrel_config  
    div(:id => "mongrel", :class => "page") {
      h3 { "Step 1b. Enter the web server's details" } 

      text "port" 
      input(:type => "text", :id => "T_mg_port", :name => 'mg_port', :size => "20", :value => '110011') 
      br
      
      text "URI Path" 
      input(:type => "text", :id => "T_mg_uri_path", :name => 'mg_uri_path', :size => "20") 
      br

      text "Bind address" 
      input(:type => "text", :id => "T_mg_bind_addr", :name => 'mg_bind_addr', :size => "20") 

      p { 
        input(:type => "button", :id => "B_mongrel_config", :value => "Go Back", :onClick => "showLayer('web_server_select')")
        input(:type => "button", :id => "C_mongrel_config", :value => "Continue", :onClick => "showLayer('database_select')") 
      }
    }
  end
  
  # Database Selection Page
  #
  def database_select 
    div(:id => "database_select", :class => "page") {
      h3 { "Step 2. Select the Database to use." } 

      text "MySQL" 
      input(:type => "radio", :id => 'R_mysql', :name => "database", :value => "mysql", :checked => true) 
      help("By default, we use MySQL, since it is widely used and does not require any additional ruby libraries besides ActiveRecord.")
      br
      
      text "SQLite" 
      input(:type => "radio", :id => 'R_sqlite', :name => "database", :value => "sqlite") 
      br
      
      text "PostgreSQL" 
      input(:type => "radio", :id => 'R_psql', :name => "database", :value => "psgsql") 
      br

      text "MSSQL" 
      input(:type => "radio", :id => 'R_mssql', :name => "database", :value => "mssql") 
      br

      text "Other" 
      input(:type => "radio", :id => 'O_othersql', :name => "database", :value => "othersql")
      input(:type => "text", :id => 'T_othersqltext', :name => 'other_database', :size => "20") 

      p { 
        input(:type => "button", :id => "B_database_select", :value => "Go Back", :onClick => "showLayer(getRadioValue('webserver'))")
        input(:type => "button", 
          :id => "C_database_select", 
          :value => "Continue", 
          :onClick => "showLayer(getRadioValue('database'));") 
      }
    }
  end

  # MySQL Setup page
  #
  def mysql_config  
    div(:id => "mysql", :class => "page") {
      h3 { "Step 2a. Configure the MySQL Database." } 

      text "Database Name" 
      input(:type => "text", :id => "T_mysql_db_name", :name => 'mysql_db_name', :size => "20") 
      br
         
      text "Username" 
      input(:type => "text", :id => "T_mysql_username", :name => 'mysql_username', :size => "20") 
      br
         
      text "Password" 
      input(:type => "text", :id => "T_mysql_password", :name => 'mysql_password', :size => "20") 
      br
      
      text "Host" 
      input(:type => "text", :id => "T_mysql_host", :name => 'mysql_host', :size => "20", :value => 'localhost') 
    
      p { 
        input(:type => "button", :id => "B_mysql_config", :value => "Go Back", :onClick => "showLayer('database_select')")
        input(:type => "button", :id => "C_mysql_config", :value => "Continue", :onClick => "showLayer('page3')") 
      }
    }
  end

  # SQLite setup page
  #
  def sqlite_config   
    div(:id => "sqlite", :class => "page") {
      h3 { "Step 2b. Configure the SQLite Database." } 
      
      text "Database Name" 
      input(:type => "text", :id => "T_sqlite_db_name", :name => 'sqlite_db_name', :size => "20") 
     
      p { 
        input(:type => "button", :id => "B_sqlite_config", :value => "Go Back", :onClick => "showLayer('database_select')")
        input(:type => "button", :id => "C_sqlite_config", :value => "Continue", :onClick => "showLayer('page3')") 
      }
    }
  end
  
  # Dummie last page for now
  # TODO - change to post to server
  #
  def page3
    div(:id => "page3", :class => "page") {
      h3 { "Step 3. XXX." } 
      
      text "XXX" 
      input(:type => "text", :id => "T22", :name => 'xxx', :size => "20") 
    
      p { 
        input(:type => "button", :id => "B3", :value => "Go Back", :onClick => "showLayer(getRadioValue('database'))")
        input(:type => "submit", :value => "Submit", :id => "submit") 
      }
    }
  end
  
  # Creates a '?' image which will display the help_text
  # upon mouse over
  # 
  def help(help_text)
    @help_count = (@help_count) ? @help_count + 1 : 0
    id = "help_#{@help_count}"
    
    img(:id => id, :height => 20, :src => "/static/q_mark.png")
    script {
      text "var #{id} = new Control.ToolTip($('#{id}'),\"#{help_text}\",{className: 'tooltip'});"
    }
  end
end


module CASServer::Views
  begin
    require 'erubis'
    ERB = Erubis::Eruby
  rescue
    require 'erb'
  end

  def layout
    self << if @use_layout
              new_erb('layout').result(binding){ yield }
            else
              yield
            end
  end

  def login
    @use_layout = true
    new_erb('login').result(binding)
  end

  def login_form
    new_erb('login_form').result(binding)
  end

  def logout
    @use_layout = true
    new_erb('logout').result(binding)
  end

  protected
  def new_erb template
    ERB.new(File.read("#{$CONF.template_erb_dir}/#{template}.html.erb"))
  end
end

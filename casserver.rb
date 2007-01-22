require 'camping'

Camping.goes :CasServer

module CasServer
end

module CasServer::Controllers
  class Login < R '/'
    def get
      @server = "URBACON"
      render :login
    end
  end
end

module CasServer::Views
  def layout
    html do
      title { 'My HomePage' }
      body { self << yield }
    end
  end

  def login
    h1 { "test" }
  end
end
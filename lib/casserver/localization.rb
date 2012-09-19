require 'sinatra/r18n'

module CASServer
  module Localization
    def self.included(mod)
      mod.module_eval do
        register Sinatra::R18n
        R18n::I18n.default = 'en'
        R18n.default_places { File.expand_path(File.join(File.dirname(__FILE__),'..','..','locales')) }
      end
    end
  end
end

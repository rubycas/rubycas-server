require 'sinatra/r18n'

module CASServer
  module Localization
    def self.included(mod)
      mod.module_eval do
        register Sinatra::R18n
        set :default_locale, 'en'
        set :translations,   './locales'
      end
    end
  end
end

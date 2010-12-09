require "gettext"
require "gettext/cgi"
require 'active_support'

module CASServer
  module Localization
    def self.included(mod)
      mod.module_eval do
        include GetText
      end
    end

    include GetText
    bindtextdomain("rubycas-server", :path => File.join(File.dirname(File.expand_path(__FILE__)), "../../locale"))

    def determine_locale(request)
      source = nil
      lang = case
      when !request.params['lang'].blank?
        source = "'lang' request variable"
        request.cookies['lang'] = request.params['lang']
        request.params['lang']
      when !request.cookies['lang'].blank?
        source = "'lang' cookie"
        request.cookies['lang']
      when !request.env['HTTP_ACCEPT_LANGUAGE'].blank?
        source = "'HTTP_ACCEPT_LANGUAGE' header"
        lang = request.env['HTTP_ACCEPT_LANGUAGE']
      when !request.env['HTTP_USER_AGENT'].blank? && request.env['HTTP_USER_AGENT'] =~ /[^a-z]([a-z]{2}(-[a-z]{2})?)[^a-z]/i
        source = "'HTTP_USER_AGENT' header"
        $~[1]
#      when !$CONF['default_locale'].blank?
#        source = "'default_locale' config option"
#        $CONF[:default_locale]
      else
        source = "default"
        "en"
      end

      $LOG.debug "Detected locale is #{lang.inspect} (from #{source})"

      lang.gsub!('_','-')

      # TODO: Need to confirm that this method of splitting the accepted
      #       language string is correct.
      if lang =~ /[,;\|]/
        langs = lang.split(/[,;\|]/)
      else
        langs = [lang]
      end

      # TODO: This method of selecting the desired language might not be
      #       standards-compliant. For example, http://www.w3.org/TR/ltli/
      #       suggests that de-de and de-*-DE might be acceptable identifiers
      #       for selecting various wildcards. The algorithm below does not
      #       currently support anything like this.

      available = available_locales

      if available.length == 1
        $LOG.warn "Only the #{available.first.inspect} localization is available. You should run `rake localization:mo` to compile support for additional languages!"
      elsif available.length == 0 # this should never actually happen
        $LOG.error "No localizations available! Run `rake localization:mo` to compile support for additional languages."
      end

      # Try to pick a locale exactly matching the desired identifier, otherwise
      # fall back to locale without region (i.e. given "en-US; de-DE", we would
      # first look for "en-US", then "en", then "de-DE", then "de").

      chosen_lang = nil
      langs.each do |l|
        a = available.find{ |a| a =~ Regexp.new("\\A#{l}\\Z", 'i') ||
                                a =~ Regexp.new("#{l}-\w*",   'i')    }
        if a
          chosen_lang = a
          break
        end
      end

      chosen_lang = "en" if chosen_lang.blank?

      $LOG.debug "Chosen locale is #{chosen_lang.inspect}"

      return chosen_lang
    end

    def available_locales
      (Dir.glob(File.join(File.dirname(File.expand_path(__FILE__)), "../../locale/[a-z]*")).map{|path| File.basename(path)} << "en").uniq.collect{|l| l.gsub('_','-')}
    end
  end
end

require "gettext"
require "gettext/cgi"

module CASServer
  include GetText
  bindtextdomain("rubycas-server", :path => File.join($APP_PATH, "/locale"))
  
  def service(*a)
    GetText.locale = determine_locale
    #puts GetText.locale.inspect
    super(*a)
  end
  
  def determine_locale
    lang = "en"
    lang = @input['lang'] unless @input['lang'].blank? 
    lang ||= @cookies['lang'] unless @cookies['lang'].blank? 
    lang ||= @env.HTTP_ACCEPT_LANGUAGE unless @env.HTTP_ACCEPT_LANGUAGE.blank?
    lang ||= @env.HTTP_USER_AGENT =~ /[^a-z]([a-z]{2}(-[a-z]{2})?)[^a-z]/i && 
              lang = $~[1] unless @env.HTTP_USER_AGENT.blank?
    @cookies['lang'] = lang
    
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
    
    # Try to pick a locale exactly matching the desired identifier, otherwise
    # fall back to locale without region (i.e. given "en-US; de-DE", we would
    # first look for "en-US", then "en", then "de-DE", then "de").
    
    chosen_lang = nil
    langs.each do |l| 
      a = available.find{|a| a == l || a =~ Regexp.new("#{l}-\w*")}
      if a
        chosen_lang = a
        break
      end
    end
    
    chosen_lang = "en" if chosen_lang.blank?
    
    return chosen_lang
  end
  
  def available_locales
    (Dir.glob(File.join($APP_PATH, "locale/[a-z]*")).map{|path| File.basename(path)} << "en").uniq.collect{|l| l.gsub('_','-')}
  end
end
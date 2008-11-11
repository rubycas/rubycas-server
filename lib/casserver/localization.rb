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
    lang = @input['lang'] unless @input['lang'].blank? 
    lang ||= @cookies['lang'] unless @cookies['lang'].blank? 
    lang ||= @env.HTTP_ACCEPT_LANGUAGE unless @env.HTTP_ACCEPT_LANGUAGE.blank?
    lang ||= @env.HTTP_USER_AGENT =~ /[^a-z]([a-z]{2}(-[a-z]{2})?)[^a-z]/i && 
              lang = $~[1] unless @env.HTTP_USER_AGENT.blank?
    @cookies['lang'] = lang
    
    if lang =~ /[,;\|]/
      langs = lang.split(/[,;\|]/)
    else
      langs = [lang]
    end
    
    available = available_locales
    
    #puts "AVAILABLE: #{available.inspect}"
    #puts "NEED ONE OF: #{langs.inspect}"
    chosen_lang = langs.each do |l| 
      a = available.find{|a| a == l || a =~ Regexp.new("#{l}-\w*")}
      break a if a
    end
    #puts "CHOSEN: #{chosen_lang.inspect}"
  
    chosen_lang = "en" if chosen_lang.blank?
    
    return chosen_lang
  end
  
  def available_locales
    (Dir.glob(File.join($APP_PATH, "locale/[a-z]*")).map{|path| File.basename(path)} << "en").uniq.collect{|l| l.gsub('_','-')}
  end
end
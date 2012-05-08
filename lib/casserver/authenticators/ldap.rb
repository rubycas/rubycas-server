require 'casserver/authenticators/base'

begin
  require 'net/ldap'
rescue LoadError
  require 'rubygems'
  begin
    gem 'net-ldap', '~> 0.1.1'
  rescue Gem::LoadError
    $stderr.puts
    $stderr.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    $stderr.puts
    $stderr.puts "To use the LDAP/AD authenticator, you must first install the 'net-ldap' gem."
    $stderr.puts "        See http://github.com/RoryO/ruby-net-ldap for details."
    $stderr.puts
    $stderr.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
  end
  require 'net/ldap'
end

# Basic LDAP authenticator. Should be compatible with OpenLDAP and other similar LDAP servers,
# although it hasn't been officially tested. See example config file for details on how
# to configure it.
class CASServer::Authenticators::LDAP < CASServer::Authenticators::Base
  def validate(credentials)
    read_standard_credentials(credentials)

    return false if @password.blank?

    raise CASServer::AuthenticatorError, "Cannot validate credentials because the authenticator hasn't yet been configured" unless @options
    raise CASServer::AuthenticatorError, "Invalid LDAP authenticator configuration!" unless @options[:ldap]
    raise CASServer::AuthenticatorError, "You must specify a server host in the LDAP configuration!" unless @options[:ldap][:host] || @options[:ldap][:server]

    raise CASServer::AuthenticatorError, "The username '#{@username}' contains invalid characters." if (@username =~ /[*\(\)\0\/]/)

    preprocess_username

    @ldap = Net::LDAP.new


    @options[:ldap][:host] ||= @options[:ldap][:server]
    @ldap.host = @options[:ldap][:host]
    @ldap.port = @options[:ldap][:port] if @options[:ldap][:port]
    @ldap.encryption(@options[:ldap][:encryption].intern) if @options[:ldap][:encryption]

    begin
      if @options[:ldap][:auth_user]
        bind_success = bind_by_username_with_preauthentication
      else
        bind_success = bind_by_username
      end

      return false unless bind_success

      entry = find_user
      extract_extra_attributes(entry)

      return true
    rescue Net::LDAP::LdapError => e
      raise CASServer::AuthenticatorError,
        "LDAP authentication failed with '#{e}'. Check your authenticator configuration."
    end
  end

  protected
    def default_username_attribute
      "cn"
    end

  private
    # Add prefix to username, if :username_prefix was specified in the :ldap config.
    def preprocess_username
      @username = @options[:ldap][:username_prefix] + @username if @options[:ldap][:username_prefix]
    end

    # Attempt to bind with the LDAP server using the username and password entered by
    # the user. If a :filter was specified in the :ldap config, the filter will be
    # added to the LDAP query for the username.
    def bind_by_username
      @ldap.bind_as(:base => @options[:ldap][:base], :password => @password, :filter => user_filter)
    end

    # If an auth_user is specified, we will connect ("pre-authenticate") with the
    # LDAP server using the authenticator account, and then attempt to bind as the
    # user who is actually trying to authenticate. Note that you need to set up
    # the special authenticator account first. Also, auth_user must be the authenticator
    # user's full CN, which is probably not the same as their username.
    #
    # This pre-authentication process is necessary because binding can only be done
    # using the CN, so having just the username is not enough. We connect as auth_user,
    # and then try to find the target user's CN based on the given username. Then we bind
    # as the target user to validate their credentials.
    def bind_by_username_with_preauthentication
      raise CASServer::AuthenticatorError, "A password must be specified in the configuration for the authenticator user!" unless
        @options[:ldap][:auth_password]

      @ldap.authenticate(@options[:ldap][:auth_user], @options[:ldap][:auth_password])

      @ldap.bind_as(:base => @options[:ldap][:base], :password => @password, :filter => user_filter)
    end

    # Combine the filter for finding the user with the optional extra filter specified in the config
    # (if any).
    def user_filter
      username_attribute = options[:ldap][:username_attribute] || default_username_attribute

      filter = Array(username_attribute).map { |ua| Net::LDAP::Filter.eq(ua, @username) }.reduce(:|)
      unless @options[:ldap][:filter].blank?
        filter &= Net::LDAP::Filter.construct(@options[:ldap][:filter])
      end

      filter
    end

    # Finds the user based on the user_filter (this is called after authentication).
    # We do this to make it possible to extract extra_attributes.
    def find_user
      results = @ldap.search( :base => options[:ldap][:base], :filter => user_filter)
      return results.first
    end

    def extract_extra_attributes(ldap_entry)
      @extra_attributes = {}
      extra_attributes_to_extract.each do |attr|
        v = ldap_entry[attr]
        next if !v || (v.respond_to?(:empty?) && v.empty?)
        if v.kind_of?(Array)
           @extra_attributes[attr] = []
           ldap_entry[attr].each do |a|
             @extra_attributes[attr] << a.to_s
           end
        else
          @extra_attributes[attr] = v.to_s
        end
      end

      if @extra_attributes.empty?
        $LOG.warn("#{self.class}: Did not read any extra_attributes for user #{@username.inspect} even though an :extra_attributes option was provided.")
      else
        $LOG.debug("#{self.class}: Read the following extra_attributes for user #{@username.inspect}: #{@extra_attributes.inspect}")
      end
      ldap_entry
    end
end

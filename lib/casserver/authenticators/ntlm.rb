# THIS AUTHENTICATOR DOES NOT WORK (not even close!)
#
# I started working on this but run into a wall, so I am commiting what I've got
# done and leaving it here with hopes of one day finishing it.
#
# The main problem is that although I've got the Lan Manager/NTLM password hash,
# I'm not sure what to do with it. i.e. I need to check it against the AD or SMB
# server or something... maybe faking an SMB share connection and using the LM
# response for authentication might do the trick?

require 'casserver/authenticators/base'

# Ruby/NTLM package from RubyForge
require 'net/ntlm'

module CASServer
  module Authenticators
    class NTLM
      # This will have to be somehow called by the top of the 'get' method
      # in the Login controller (maybe via a hook?)... if this code fails
      # then the controller should fall back to some other method of authentication
      # (probably AD/LDAP or something).
      def filter_for_top_of_login_get_controller_method
        $LOG.debug @env.inspect
        if @env['HTTP_AUTHORIZATION'] =~ /NTLM ([^\s]+)/
          # if we're here, then the client has sent back a Type1 or Type3 message
          # in reply to our NTLM challenge or our Type2 message
          data_raw = Base64.decode64($~[1])
          $LOG.debug "T1 RAW: #{t1_raw}"
          t = Net::NTLM::Message::Message.parse(t1_raw)
          if t.kind_of? Net::NTLM::Type1
            t1 = t
          elsif t.kind_of? Net::NTLM::Type3
            t3 = t
          else
            raise "Invalid NTLM reply from client."
          end

          if t1
            $LOG.debug "T1: #{t1.inspect}"

            # now put together a Type2 message asking for the client to send
            # back NTLM credentials (LM hash and such)
            t2 = Net::NTLM::Message::Type2.new
            t2.set_flag :UNICODE
            t2.set_flag :NTLM
            t2.context = 0x0000000000000000 # this can probably just be left unassigned
            t2.challenge = 0x0123456789abcdef # this should be a random 8-byte integer

            $LOG.debug "T2: #{t2.inspect}"
            $LOG.debug "T2: #{t2.serialize}"
            headers["WWW-Authenticate"] = "NTLM #{t2.encode64}"

            # the client should respond to this with a Type3 message...
            r('401', '', headers)
            return
          else
            # NOTE: for some reason the server never receives the T3 response, even though monitoring
            # the HTTP traffic I can see that the client does send it back... there's probably
            # another bug hiding somewhere here

            lm_response = t3.lm_response
            ntlm_response = t3.ntlm_response
            username = t3.user
            # this is where we run up against a wall... we need some way to check the lm and/or ntlm
            # reponse against the authentication server (probably Active Directory)... maybe a samba
            # call would do it?
            $LOG.debug "T3 LM: #{lm_response.inspect}"
            $LOG.debug "T3 NTLM: #{ntlm_response.inspect}"

            # assuming the authentication was successful, we'll now need to do something in the
            # controller acting as if we'd received correct login credentials (i.e. proceed as if
            # CAS authentication was successful).... if authentication failed, then we should
            # just fall back to old-school web-based authentication, asking the user to enter
            # their username and password the normal CAS way
          end
        else
          # this sends the initial NTLM challenge, asking the browser
          # to send back a Type1 message
          headers['WWW-Authenticate'] = "NTLM"
          headers['Connection'] = "Close"
          r('401', '', headers)
          return
        end
      end
    end
  end
end

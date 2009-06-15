require 'config/requirements'
require 'config/hoe' # setup Hoe + all gem configuration

Dir['tasks/**/*.rake'].each { |rake| load rake }

desc "generate a self signed SSL certificate (in order to get going easily)"
task :generate_ssl_certificate do
  `mkdir -p ssl/newcerts ssl/private`
  File.open("ssl/openssl.cnf", "w") do |f|
    f.write <<-EOF
    #
    # OpenSSL configuration file.
    #

    # Establish working directory.

    dir			= .

    [ ca ]
    default_ca		= CA_default

    [ CA_default ]
    serial			= $dir/serial
    database		= $dir/index.txt
    new_certs_dir		= $dir/newcerts
    certificate		= $dir/cacert.pem
    private_key		= $dir/private/cakey.pem
    default_days		= 365
    default_md		= md5
    preserve		= no
    email_in_dn		= no
    nameopt			= default_ca
    certopt			= default_ca
    policy			= policy_match

    [ policy_match ]
    countryName		= match
    stateOrProvinceName	= match
    organizationName	= match
    organizationalUnitName	= optional
    commonName		= supplied
    emailAddress		= optional

    [ req ]
    default_bits		= 1024			# Size of keys
    default_keyfile		= key.pem		# name of generated keys
    default_md		= md5			# message digest algorithm
    string_mask		= nombstr		# permitted characters
    distinguished_name	= req_distinguished_name
    req_extensions		= v3_req

    [ req_distinguished_name ]
    # Variable name		  Prompt string
    #----------------------	  ----------------------------------
    0.organizationName	= Organization Name (company)
    organizationalUnitName	= Organizational Unit Name (department, division)
    emailAddress		= Email Address
    emailAddress_max	= 40
    localityName		= Locality Name (city, district)
    stateOrProvinceName	= State or Province Name (full name)
    countryName		= Country Name (2 letter code)
    countryName_min		= 2
    countryName_max		= 2
    commonName		= Common Name (hostname, IP, or your name)
    commonName_max		= 64

    # Default values for the above, for consistency and less typing.
    # Variable name			  Value
    #------------------------------	  ------------------------------
    0.organizationName_default	= The Sample Company
    localityName_default		= Metropolis
    stateOrProvinceName_default	= New York
    countryName_default		= US
    commonName_default		= localhost

    [ v3_ca ]
    basicConstraints	= CA:TRUE
    subjectKeyIdentifier	= hash
    authorityKeyIdentifier	= keyid:always,issuer:always

    [ v3_req ]
    basicConstraints	= CA:FALSE
    subjectKeyIdentifier	= hash
    EOF
  end

  `cd ssl && echo '01' > serial`
  `cd ssl && touch index.txt`

  puts
  puts "When asked for a passphrase enter one, for example rubycas"
  puts

  `cd ssl && openssl req -new -x509 -extensions v3_ca -keyout private/cakey.pem -out cacert.pem -days 365 -config ./openssl.cnf`
  `cd ssl && openssl req -new -nodes -out req.pem -config ./openssl.cnf`
  `cd ssl && openssl ca -out cert.pem -config ./openssl.cnf -infiles req.pem`




  puts
  puts "If you are using Firefox and want to access the CAS server through localhost you need to add an exception:"
  puts " 1. Go to Preferences > Advanced > Encryption > View Certificates"
  puts " 2. Click the Tab Servers"
  puts " 3. Click the Button Add Exception"
  puts " 4. Enter https://localhost:<port> into the textfield and press Get Certificate"
  puts " 5. Then press View"
  puts " 6. Then press Confirm Security Exception"

end

desc "clear all generated files for SSL certificate"
task :clear_ssl_certificate do
  `rm -rf ssl`
end

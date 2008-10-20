Gem::Specification.new do |s|
  s.name = %q{rubycas-server}
  s.version = "0.6.99.336"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Zukowski"]
  s.date = %q{2008-10-14}
  s.description = %q{Provides single sign-on authentication for web applications using the CAS protocol.}
  s.email = ["matt@zukowski.ca"]
  s.executables = ["rubycas-server", "rubycas-server-ctl"]
  s.extra_rdoc_files = ["CHANGELOG.txt", "History.txt", "LICENSE.txt", "Manifest.txt", "PostInstall.txt", "README.txt", "website/index.txt"]
  s.files = ["CHANGELOG.txt", "History.txt", "LICENSE.txt", "Manifest.txt", "PostInstall.txt", "README.txt", "Rakefile", "bin/rubycas-server", "bin/rubycas-server-ctl", "casserver.db", "casserver.log", "casserver_db.log", "config.example.yml", "config/hoe.rb", "config/requirements.rb", "custom_views.example.rb", "lib/casserver.rb", "lib/casserver/authenticators/active_directory_ldap.rb", "lib/casserver/authenticators/base.rb", "lib/casserver/authenticators/client_certificate.rb", "lib/casserver/authenticators/ldap.rb", "lib/casserver/authenticators/ntlm.rb", "lib/casserver/authenticators/open_id.rb", "lib/casserver/authenticators/sql.rb", "lib/casserver/authenticators/sql_encrypted.rb", "lib/casserver/authenticators/sql_md5.rb", "lib/casserver/authenticators/test.rb", "lib/casserver/cas.rb", "lib/casserver/conf.rb", "lib/casserver/controllers.rb", "lib/casserver/environment.rb", "lib/casserver/models.rb", "lib/casserver/postambles.rb", "lib/casserver/utils.rb", "lib/casserver/version.rb", "lib/casserver/views.rb", "lib/rubycas-server.rb", "lib/rubycas-server/version.rb", "lib/themes/cas.css", "lib/themes/notice.png", "lib/themes/ok.png", "lib/themes/simple/bg.png", "lib/themes/simple/login_box_bg.png", "lib/themes/simple/logo.png", "lib/themes/simple/theme.css", "lib/themes/urbacon/bg.png", "lib/themes/urbacon/login_box_bg.png", "lib/themes/urbacon/logo.png", "lib/themes/urbacon/theme.css", "lib/themes/warning.png", "misc/basic_cas_single_signon_mechanism_diagram.png", "misc/basic_cas_single_signon_mechanism_diagram.svg", "resources/init.d.sh", "script/console", "script/destroy", "script/generate", "script/txt2html", "setup.rb", "tasks/deployment.rake", "tasks/environment.rake", "tasks/website.rake", "vendor/isaac_0.9.1/LICENSE", "vendor/isaac_0.9.1/README", "vendor/isaac_0.9.1/TODO", "vendor/isaac_0.9.1/VERSIONS", "vendor/isaac_0.9.1/crypt/ISAAC.rb", "vendor/isaac_0.9.1/isaac.gemspec", "vendor/isaac_0.9.1/setup.rb", "vendor/isaac_0.9.1/test/TC_ISAAC.rb", "website/index.html", "website/index.txt", "website/javascripts/rounded_corners_lite.inc.js", "website/stylesheets/screen.css", "website/template.html.erb"]
  s.has_rdoc = true
  s.homepage = %q{http://rubycas-server.rubyforge.org}
  s.post_install_message = %q{
For more information on RubyCAS-Server, see http://code.google.com/p/rubycas-server

}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rubycas-server}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Provides single sign-on authentication for web applications using the CAS protocol.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_development_dependency(%q<hoe>, [">= 1.7.0"])
    else
      s.add_dependency(%q<hoe>, [">= 1.7.0"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.7.0"])
  end
end

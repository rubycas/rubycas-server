# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rubycas-server}
  s.version = "0.8.0.20090227"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Zukowski"]
  s.date = %q{2009-02-25}
  s.description = %q{Provides single sign-on authentication for web applications using the CAS protocol.}
  s.email = ["matt@zukowski.ca"]
  s.executables = ["rubycas-server", "rubycas-server-ctl"]
  s.extra_rdoc_files = ["CHANGELOG.txt", "History.txt", "LICENSE.txt", "Manifest.txt", "PostInstall.txt", "README.txt"]
  s.files = ["CHANGELOG.txt", "History.txt", "LICENSE.txt", "Manifest.txt", "PostInstall.txt", "README.txt", "Rakefile", "bin/rubycas-server", "bin/rubycas-server-ctl", "config.example.yml", "config.ru", "config/hoe.rb", "config/requirements.rb", "custom_views.example.rb", "lib/casserver.rb", "lib/casserver/authenticators/active_directory_ldap.rb", "lib/casserver/authenticators/base.rb", "lib/casserver/authenticators/client_certificate.rb", "lib/casserver/authenticators/google.rb", "lib/casserver/authenticators/ldap.rb", "lib/casserver/authenticators/ntlm.rb", "lib/casserver/authenticators/open_id.rb", "lib/casserver/authenticators/sql.rb", "lib/casserver/authenticators/sql_encrypted.rb", "lib/casserver/authenticators/sql_md5.rb", "lib/casserver/authenticators/sql_rest_auth.rb", "lib/casserver/authenticators/test.rb", "lib/casserver/cas.rb", "lib/casserver/conf.rb", "lib/casserver/controllers.rb", "lib/casserver/environment.rb", "lib/casserver/localization.rb", "lib/casserver/models.rb", "lib/casserver/postambles.rb", "lib/casserver/utils.rb", "lib/casserver/version.rb", "lib/casserver/views.rb", "lib/rubycas-server.rb", "lib/rubycas-server/version.rb", "lib/themes/cas.css", "lib/themes/notice.png", "lib/themes/ok.png", "lib/themes/simple/bg.png", "lib/themes/simple/login_box_bg.png", "lib/themes/simple/logo.png", "lib/themes/simple/theme.css", "lib/themes/urbacon/bg.png", "lib/themes/urbacon/login_box_bg.png", "lib/themes/urbacon/logo.png", "lib/themes/urbacon/theme.css", "lib/themes/warning.png", "po/de_DE/rubycas-server.po", "po/es_ES/rubycas-server.po", "po/fr_FR/rubycas-server.po", "po/ja_JP/rubycas-server.po", "po/pl_PL/rubycas-server.po", "po/ru_RU/rubycas-server.po", "po/rubycas-server.pot", "resources/init.d.sh", "script/console", "script/destroy", "script/generate", "script/txt2html", "setup.rb", "tasks/deployment.rake", "tasks/environment.rake", "tasks/localization.rake", "tasks/website.rake", "vendor/isaac_0.9.1/LICENSE", "vendor/isaac_0.9.1/README", "vendor/isaac_0.9.1/TODO", "vendor/isaac_0.9.1/VERSIONS", "vendor/isaac_0.9.1/crypt/ISAAC.rb", "vendor/isaac_0.9.1/isaac.gemspec", "vendor/isaac_0.9.1/setup.rb", "vendor/isaac_0.9.1/test/TC_ISAAC.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://rubycas-server.rubyforge.org}
  s.post_install_message = %q{
For more information on RubyCAS-Server, see http://code.google.com/p/rubycas-server

If you plan on using RubyCAS-Server with languages other than English, please cd into the
RubyCAS-Server installation directory (where the gem is installed) and type `rake mo` to
build the LOCALE_LC files.

}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rubycas-server}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Provides single sign-on authentication for web applications using the CAS protocol.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_runtime_dependency(%q<activerecord>, [">= 0"])
      s.add_runtime_dependency(%q<gettext>, [">= 0"])
      s.add_runtime_dependency(%q<picnic>, [">= 0.7.999"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.2"])
    else
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<activerecord>, [">= 0"])
      s.add_dependency(%q<gettext>, [">= 0"])
      s.add_dependency(%q<picnic>, [">= 0.7.999"])
      s.add_dependency(%q<hoe>, [">= 1.8.2"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<activerecord>, [">= 0"])
    s.add_dependency(%q<gettext>, [">= 0"])
    s.add_dependency(%q<picnic>, [">= 0.7.999"])
    s.add_dependency(%q<hoe>, [">= 1.8.2"])
  end
end

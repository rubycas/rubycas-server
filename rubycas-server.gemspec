$gemspec = Gem::Specification.new do |s|
  s.name     = 'rubycas-server'
  s.version  = '1.1.2'
  s.authors  = ["Matt Zukowski"]
  s.email    = ["matt@zukowski.ca"]
  s.homepage = 'https://github.com/rubycas/rubycas-server'
  s.platform = Gem::Platform::RUBY
  s.summary  = %q{Provides single sign-on authentication for web applications using the CAS protocol.}
  s.description  = %q{Provides single sign-on authentication for web applications using the CAS protocol.}

  s.files  = [
    "CHANGELOG", "LICENSE", "README.md", "Rakefile", "setup.rb",
    "bin/*", "db/**/*", "lib/**/*.rb", "public/**/*", "locales/**/*", "resources/*.*",
    "config.ru", "config/**/*", "tasks/**/*.rake", "vendor/**/*", "script/*", "lib/**/*.erb", "lib/**/*.builder",
    "Gemfile", "rubycas-server.gemspec"
  ].map{|p| Dir[p]}.flatten

  s.test_files = `git ls-files -- spec`.split("\n")

  s.executables = ["rubycas-server"]
  s.bindir = "bin"
  s.require_path = "lib"

  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README.md"]

  s.has_rdoc = true
  s.post_install_message = "
For more information on RubyCAS-Server, see http://code.google.com/p/rubycas-server

"

  s.add_dependency("activerecord", ">= 2.3.12", "< 3.1")
  s.add_dependency("activesupport", ">= 2.3.12", "< 3.1")
  s.add_dependency("sinatra", "~> 1.0")
  s.add_dependency("sinatra-r18n", '~> 1.1.0')
  s.add_dependency("crypt-isaac", "~> 0.9.1")

  s.add_development_dependency("rack-test")
  s.add_development_dependency("capybara", '1.1.2')
  s.add_development_dependency("rspec")
  s.add_development_dependency("rspec-core")
  s.add_development_dependency("rake", "0.8.7")
  s.add_development_dependency("sqlite3", "~> 1.3.1")
  s.add_development_dependency("guard", "~> 1.4.0")
  s.add_development_dependency("guard-rspec", "2.0.0")

  # pull in os specific FS monitoring lib for guard
  case RUBY_PLATFORM
  when /darwin/i
    s.add_development_dependency("rb-fsevent", "~> 0.9.2")
  when /linux/i
    s.add_development_dependency("rb-inotify", "~> 0.8.8")
  when /mswin|bccwin|wince/i
    s.add_development_dependency('wdm', '~> 0.0.3') if RUBY_VERSION >= '1.9.2'
    s.add_development_dependency('win32console', "~> 1.3.2")
  end

  # for authenticator specs
  s.add_development_dependency("net-ldap", "~> 0.1.1")
  s.add_development_dependency("activeresource", ">= 2.3.12", "< 3.1")

  s.rdoc_options = [
    '--quiet', '--title', 'RubyCAS-Server Documentation', '--opname',
    'index.html', '--line-numbers', '--main', 'README.md', '--inline-source'
  ]
end

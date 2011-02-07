
$gemspec = Gem::Specification.new do |s|
  s.name     = 'rubycas-server'
  s.version  = '1.0.a'
  s.authors  = ["Matt Zukowski"]
  s.email    = ["matt@zukowski.ca"]
  s.homepage = 'http://code.google.com/p/rubycas-server/'
  s.platform = Gem::Platform::RUBY
  s.summary  = %q{Provides single sign-on authentication for web applications using the CAS protocol.}
  s.description  = %q{Provides single sign-on authentication for web applications using the CAS protocol.}

  s.files  = [
    "CHANGELOG", "LICENSE", "README.md", "Rakefile", "setup.rb",
    "bin/*", "db/*", "lib/**/*.rb", "public/**/*", "po/**/*", "mo/**/*", "resources/*.*",
    "tasks/**/*.rake", "vendor/**/*", "script/*", "lib/**/*.erb", "lib/**/*.builder",
    "Gemfile", "rubycas-server.gemspec"
  ].map{|p| Dir[p]}.flatten

  s.test_files = `git ls-files -- spec`.split("\n")

  s.executables = ["rubycas-server"]
  s.bindir = "bin"
  s.require_path = "lib"

  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README.md"]

  s.has_rdoc = true
  s.post_install_message = %q{
For more information on RubyCAS-Server, see http://code.google.com/p/rubycas-server

If you plan on using RubyCAS-Server with languages other than English, please cd into the
RubyCAS-Server installation directory (where the gem is installed) and type `rake localization:mo`
to build the LOCALE_LC files.

}

  s.add_dependency("activerecord", "~> 3.0.0")
  s.add_dependency("activesupport", "~> 3.0.0")
  s.add_dependency("sinatra", "~> 1.0")
  s.add_dependency("gettext", "~> 2.1.0")
  s.add_dependency("crypt-isaac", "~> 0.9.1")

  s.add_development_dependency("rack-test")
  s.add_development_dependency("capybara")
  s.add_development_dependency("rspec")
  s.add_development_dependency("rspec-core")
  s.add_development_dependency("sqlite3", "~> 1.3.1")

  s.rdoc_options = [
    '--quiet', '--title', 'RubyCAS-Server Documentation', '--opname',
    'index.html', '--line-numbers', '--main', 'README.md', '--inline-source'
  ]
end

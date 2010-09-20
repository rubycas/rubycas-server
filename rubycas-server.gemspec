require File.expand_path("../lib/casserver/version", __FILE__)

$gemspec = Gem::Specification.new do |s|
  s.name     = 'rubycas-server'
  s.version  = CASServer::VERSION::STRING
  s.authors  = ["Matt Zukowski"]
  s.email    = ["matt@zukowski.ca"]
  s.homepage = 'http://code.google.com/p/rubycas-server/'
  s.platform = Gem::Platform::RUBY
  s.summary  = %q{Provides single sign-on authentication for web applications using the CAS protocol.}

  s.files  = [
    "CHANGELOG", "LICENSE", "README.md", "Rakefile", "setup.rb",
    "bin/*", "lib/**/*.rb", "public/**/*", "po/**/*", "resources/*.*",
    "tasks/**/*.rake", "vendor/**/*", "script/*"
  ].map{|p| Dir[p]}.flatten

  s.executables = ["rubycas-server", "rubycas-server-ctl"]
  s.bindir = "bin"
  s.require_path = "lib"

  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README.md"]

  s.has_rdoc = true
  s.post_install_message = %q{
For more information on RubyCAS-Server, see http://code.google.com/p/rubycas-server

If you plan on using RubyCAS-Server with languages other than English, please cd into the
RubyCAS-Server installation directory (where the gem is installed) and type `rake mo` to
build the LOCALE_LC files.
}

  s.rdoc_options = [
    '--quiet', '--title', 'rubycas-server documentation', '--opname',
    'index.html', '--line-numbers', '--main', 'README.md', '--inline-source'
  ]

  s.add_runtime_dependency 'activesupport', '~> 3.0.0'
  s.add_runtime_dependency 'activerecord',  '~> 3.0.0'
  s.add_runtime_dependency 'gettext',       '~> 2.1.0'
  s.add_runtime_dependency 'sinatra',       '~> 1.0'
end

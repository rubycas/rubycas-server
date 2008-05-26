require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/contrib/rubyforgepublisher'
require 'fileutils'
require 'hoe'
include FileUtils
require File.join(File.dirname(__FILE__), 'lib', 'casserver', 'version')

AUTHOR = ["Matt Zukowski", "Jason Zylks"]  # can also be an array of Authors
EMAIL = ["matt at roughest dot net"]
DESCRIPTION = "Provides single sign on for web applications using the CAS protocol."
GEM_NAME = "rubycas-server" # what ppl will type to install your gem
RUBYFORGE_PROJECT = "rubycas-server" # The unix name for your project
HOMEPATH = "http://#{RUBYFORGE_PROJECT}.rubyforge.org"

DEPS = [
  ['activesupport', '>= 1.4.0'],
  ['activerecord', '>=1.15.3'],
  ['picnic', '>=0.6.4']
]


NAME = "rubycas-server"
#REV = nil
REV = `svn info`[/Revision: (\d+)/, 1] rescue nil
VERS = ENV['VERSION'] || (CASServer::VERSION::STRING + (REV ? ".#{REV}" : ""))
                          CLEAN.include ['**/.*.sw?', '*.gem', '.config']
RDOC_OPTS = ['--quiet', '--title', "RubyCAS-Server #{VERS} Documentation",
    "--opname", "index.html",
    "--line-numbers", 
    "--main", "README",
    "--inline-source"]

class Hoe
  def extra_deps 
    @extra_deps.reject { |x| Array(x).first == 'hoe' } 
  end 
end

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
hoe = Hoe.new(GEM_NAME, VERS) do |p|
  p.author = AUTHOR 
  p.description = DESCRIPTION
  p.email = EMAIL
  p.summary = DESCRIPTION
  p.url = HOMEPATH
  p.rubyforge_name = RUBYFORGE_PROJECT if RUBYFORGE_PROJECT
  p.test_globs = ["test/**/test_*.rb"]
  p.clean_globs = CLEAN  #An array of file patterns to delete on clean.
  
  # == Optional
  p.extra_deps = DEPS
  p.spec_extras = {:executables => ['rubycas-server', 'rubycas-server-ctl']}
end

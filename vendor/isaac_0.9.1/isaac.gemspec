#####
# Crypt::ISAAC
#   http://rubyforge.org/projects/crypt-isaac/
#   Copyright 2004-2005 Kirk Haines
#
#   Licensed under the Ruby License.  See the README for details.
#
#####

spec = Gem::Specification.new do |s|
  s.name              = 'Crypt::ISAAC'
  s.version           = '0.9.1'
  s.summary           = %q(Ruby implementation of the ISAAC PRNG)
  s.platform          = Gem::Platform::RUBY

  s.has_rdoc          = true
  s.rdoc_options      = %w(--title Crypt::ISAAC --main README --line-numbers)
  s.extra_rdoc_files  = %w(README)

  s.files = %w(README LICENSE TODO VERSIONS setup.rb isaac.gemspec test/TC_ISAAC.rb crypt/ISAAC.rb)

  s.test_files = ['test/TC_ISAAC.rb']

  s.require_paths     = %w(crypt)

  s.author            = %q(Kirk Haines)
  s.email             = %q(khaines@enigo.com)
  s.rubyforge_project = %q(crypt-isaac)
  s.homepage          = %q(http://rubyforge.org/projects/crypt-isaac)
  description         = []
  File.open("README") do |file|
    file.each do |line|
      line.chomp!
      break if line.empty?
      description << "#{line.gsub(/\[\d\]/, '')}"
    end
  end
  s.description = description[1..-1].join(" ")
end

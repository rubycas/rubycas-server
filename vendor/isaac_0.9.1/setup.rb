require 'rbconfig'
require 'fileutils'
require 'pp'
require 'optparse'
require 'yaml'

module Package

class SpecificationError < StandardError; end
# forward declaration of the specification classes so we can keep all
# constants here
class PackageSpecification_1_0; end
# Default semantics
PackageSpecification = PackageSpecification_1_0

#TODO: could get this collected automatically with Class#inherited etc
SEMANTICS = { "1.0" => PackageSpecification_1_0 }

KINDS = [
  :bin, :lib, :ext, :data, :conf, :doc
]

#{{{ list of files to be ignored stolen from setup.rb
mapping = { '.' => '\.', '$' => '\$', '#' => '\#', '*' => '.*' }
ignore_files = %w[core RCSLOG tags TAGS .make.state .nse_depinfo 
      #* .#* cvslog.* ,* .del-* *.olb *~ *.old *.bak *.BAK *.orig *.rej _$* *$
      *.org *.in .* ] 
#end of robbery
IGNORE_FILES = ignore_files.map do |x|
  Regexp.new('\A' + x.gsub(/[\.\$\#\*]/){|c| mapping[c]} + '\z')
end

def self.config(name)
  # XXX use pathname
  prefix = Regexp.quote(Config::CONFIG["prefix"])
  exec_prefix = Regexp.quote(Config::CONFIG["exec_prefix"])
  Config::CONFIG[name].gsub(/\A\/?(#{prefix}|#{exec_prefix})\/?/, '')
end

SITE_DIRS = {
  :bin  => config("bindir"),
  :lib  => config("sitelibdir"),
  :ext  => config("sitearchdir"),
  :data => config("datadir"),
  :conf => config("sysconfdir"),
  :doc  => File.join(config("datadir"), "doc"),
}

VENDOR_DIRS = {
  :bin  => config("bindir"),
  :lib  => config("rubylibdir"),
  :ext  => config("archdir"),
  :data => config("datadir"),
  :conf => config("sysconfdir"),
  :doc  => File.join(config("datadir"), "doc"),
}

MODES = {
  :bin  => 0755,
  :lib  => 0644,
  :ext  => 0755,  # was: 0555,
  :data => 0644,
  :conf => 0644,
  :doc  => 0644,
}


SETUP_OPTIONS = {:parse_cmdline => true, :load_conf => true, :run_tasks => true}

def self.setup(version, options = {}, &instructions)
  prefixes = dirs = nil
  options = SETUP_OPTIONS.dup.update(options)

  if options[:load_conf] && File.exist?("config.save")
    config = YAML.load_file "config.save"
    prefixes = config[:prefixes]
    dirs = config[:dirs]
  end

  pkg = package_specification_with_semantics(version).new(prefixes, dirs)
  pkg.parse_command_line if options[:parse_cmdline]
  pkg.instance_eval(&instructions)

  pkg.run_tasks if options[:run_tasks]

#   pkg.install
  pkg
end

def self.package_specification_with_semantics(version)
  #XXX: implement the full x.y(.z)? semantics
  r = SEMANTICS[version]
  raise SpecificationError, "Unknown version #{version}." unless r
  r
end


module Actions
  
  class InstallFile

    attr_reader :source, :destination, :mode

    def initialize(source, destination, mode, options)
      @source = source
      @destination = destination
      @mode = mode
      @options = options
    end

    def install
      FileUtils.install @source, File.join(@options.destdir, @destination),
                                 {:verbose => @options.verbose,
                                  :noop => @options.noop, :mode => @mode }
    end

    def hash
      [@source.hash, @destination.hash].hash
    end

    def eql?(other)
      self.class == other.class && 
        @source == other.source &&
          @destination == other.destination &&
            @mode == other.mode
    end

    def <=>(other)
      FULL_ORDER[self, other] || self.destination <=> other.destination
    end
  end

  class MkDir

    attr_reader :directory

    def initialize(directory, options)
      @directory = directory
      @options = options
    end

    def install
      FileUtils.mkdir_p File.join(@options.destdir, @directory),
                                  {:verbose => @options.verbose,
                                   :noop => @options.noop }
    end

    def <=>(other)
      FULL_ORDER[self, other] || self.directory <=> other.directory 
    end
  end

  class FixShebang

    attr_reader :destination

    def initialize(destination, options)
      @options = options
      @destination = destination
    end

    def install
      path = File.join(@options.destdir, @destination)
      fix_shebang(path)
    end

    # taken from rpa-base, originally based on setup.rb's
    # modify: #!/usr/bin/ruby
    # modify: #! /usr/bin/ruby
    # modify: #!ruby
    # not modify: #!/usr/bin/env ruby
    SHEBANG_RE = /\A\#!\s*\S*ruby\S*/

    #TODO allow the ruby-prog to be placed in the shebang line to be passed as
    # an option
    def fix_shebang(path)
      tmpfile = path + '.tmp'
      begin
        #XXX: needed at all?
        # it seems that FileUtils doesn't expose its default output
        #   @fileutils_output = $stderr
        # we might want to allow this to be redirected.
        $stderr.puts "shebang:open #{tmpfile}" if @options.verbose
        unless @options.noop
          File.open(path) do |r|
            File.open(tmpfile, 'w', 0755) do |w|
              first = r.gets
              return unless SHEBANG_RE =~ first
              w.print first.sub(SHEBANG_RE, '#!' + Config::CONFIG['ruby-prog'])
              w.write r.read
            end
          end
        end
        FileUtils.mv(tmpfile, path, :verbose => @options.verbose,
                     :noop => @options.noop)
      ensure
        FileUtils.rm_f(tmpfile, :verbose => @options.verbose,
                       :noop => @options.noop)
      end
    end

    def <=>(other)
      FULL_ORDER[self, other] || self.destination <=> other.destination
    end

    def hash
      @destination.hash
    end

    def eql?(other)
      self.class == other.class && self.destination == other.destination
    end
  end

  order = [MkDir, InstallFile, FixShebang]
  FULL_ORDER = lambda do |me, other|
    a, b = order.index(me.class), order.index(other.class)
    if a && b
      (r = a - b) == 0 ? nil : r
    else
      -1 # arbitrary
    end
  end

  class ActionList < Array

    def directories!(options)
      dirnames = []
      map! { |d|
        if d.kind_of?(InstallFile) && !dirnames.include?(File.dirname(d.destination))
          dirnames << File.dirname(d.destination)
          [MkDir.new(File.dirname(d.destination), options), d]
        else
          d
        end
      }
      flatten!
    end

    def run(task)
      each { |action| action.__send__ task }
    end
  end

end # module Actions

Options = Struct.new(:noop, :verbose, :destdir)

class PackageSpecification_1_0

  TASKS = %w[config setup install test show]
  # default options for translate(foo => bar)
  TRANSLATE_DEFAULT_OPTIONS = { :inherit => true }

  def self.declare_file_type(args, &handle_arg)
    str_arr_p = lambda{|x| Array === x && x.all?{|y| String === y}}
    
    # strict type checking --- we don't want this to be extended arbitrarily
    unless args.size == 1 && Hash === args.first && 
           args.first.all?{|f,r| [Proc, String, NilClass].include?(r.class) &&
                                 (String === f || str_arr_p[f])} or
           args.all?{|x| String === x || str_arr_p[x]}
      raise SpecificationError, 
        "Unspecified semantics for the given arguments: #{args.inspect}"
    end

    if args.size == 1 && Hash === args.first 
      args.first.to_a.each do |file, rename_info|
        if Array === file
          # ignoring boring files
          handle_arg.call(file, true, rename_info)
        else
          # we do want "boring" files given explicitly
          handle_arg.call([file], false, rename_info)
        end
      end
    else
      args.each do |a|
        if Array === a
          a.each{|file| handle_arg.call(file, true, nil)}
        else
          handle_arg.call(a, false, nil)
        end
      end
    end
  end
  
  #{{{ define the file tagging methods
  KINDS.each { |kind|
    define_method(kind) { |*args| # if this were 1.9 we could also take a block
      bin_callback = lambda do |kind_, type, dest, options|
        next if kind_ != :bin || type == :dir
        @actions << Actions::FixShebang.new(dest, options)
      end
      #TODO: refactor
      self.class.declare_file_type(args) do |files, ignore_p, opt_rename_info|
        files.each do |file|
          next if ignore_p && IGNORE_FILES.any?{|re| re.match(file)}
          add_file(kind, file, opt_rename_info, &bin_callback)
        end
      end
    }
  }

  def unit_test(*files)
    @unit_tests.concat files.flatten
  end

  attr_accessor :actions, :options

  def self.metadata(name)
    define_method(name) { |*args|
      if args.size == 1
        @metadata[name] = args.first
      end
      @metadata[name]
    }
  end

  metadata :name
  metadata :version
  metadata :author


  def translate_dir(kind, dir)
    replaced_dir_parts = dir.split(%r{/})
    kept_dir_parts = []
    loop do
      replaced_path = replaced_dir_parts.join("/")
      target, options = @translate[kind][replaced_path]
      options ||= TRANSLATE_DEFAULT_OPTIONS
      if target && (replaced_path == dir || options[:inherit])
        dir = (target != '' ? File.join(target, *kept_dir_parts) : 
                              File.join(*kept_dir_parts))
        break
      end
      break if replaced_dir_parts.empty?
      kept_dir_parts.unshift replaced_dir_parts.pop
    end
    dir
  end
  
  def add_file(kind, filename, new_filename_info, &callback)
    #TODO: refactor!!!
    if File.directory? filename #XXX setup.rb and rpa-base defined File.dir?
                                #    to cope with some win32 issue
      dir = filename.sub(/\A\.\//, "").sub(/\/\z/, "")
      dest = File.join(@prefixes[kind], @dirs[kind], translate_dir(kind, dir))
      @actions << Actions::MkDir.new(dest, @options)
      callback.call(kind, :dir, dest, @options) if block_given?
    else
      if new_filename_info
        case new_filename_info
        when Proc
          dest_name = new_filename_info.call(filename.dup)
        else
          dest_name = new_filename_info.dup
        end
      else
        dest_name = filename.dup
      end

      dirname = File.dirname(dest_name)
      dirname = "" if dirname == "."
      dest_name = File.join(translate_dir(kind, dirname), File.basename(dest_name))

      dest = File.join(@prefixes[kind], @dirs[kind], dest_name)
      @actions << Actions::InstallFile.new(filename, dest, MODES[kind], @options)
      callback.call(kind, :file, dest, @options) if block_given?
    end
  end

  def initialize(prefixes = nil, dirs = nil)
    @prefix = Config::CONFIG["prefix"].gsub(/\A\//, '')
    @translate = {}
    @prefixes = (prefixes || {}).dup
    KINDS.each { |kind|
      @prefixes[kind] = @prefix unless prefixes
      @translate[kind] = {}
    }

    @dirs = (dirs || {}).dup
    @dirs.update SITE_DIRS unless dirs

    @actions = Actions::ActionList.new

    @metadata = {}
    @unit_tests = []

    @options = Options.new
    @options.verbose = true
    @options.noop = false                # XXX for testing
    @options.destdir = ''

    @tasks = []
  end

  def aoki
    (KINDS - [:ext]).each { |kind|
      translate(kind, kind.to_s => "", :inherit => true)
      __send__ kind, Dir["#{kind}/**/*"]
    }
    translate(:ext, "ext/*" => "", :inherit => true)
    ext Dir["ext/**/*.#{Config::CONFIG['DLEXT']}"]
  end

  def install
    puts "Installing #{name || "unknown package"} #{version}..."  if options.verbose

    actions.uniq!
    actions.sort!
    actions.directories!(options)

    #pp self

    actions.run :install
  end

  def test
    unless @unit_tests.empty?
      puts "Testing #{name || "unknown package"} #{version}..."  if options.verbose
      require 'test/unit'
      unless options.noop
        t = Test::Unit::AutoRunner.new(true)
        t.process_args(@unit_tests)
        t.run  
      end
    end
  end

  def config
    File.open("config.save", "w") { |f|
      YAML.dump({:prefixes => @prefixes, :dirs => @dirs}, f)
    }
  end

  def show
    KINDS.each { |kind|
      puts "#{kind}\t#{File.join(options.destdir, @prefixes[kind], @dirs[kind])}"
    }
  end

  def translate(kind, additional_translations)
    default_opts = TRANSLATE_DEFAULT_OPTIONS.dup
    key_val_pairs = additional_translations.to_a
    option_pairs = key_val_pairs.select{|(k,v)| Symbol === k}
    default_opts.update(Hash[*option_pairs.flatten])
    
    (key_val_pairs - option_pairs).each do |key, val|
      add_translation(kind, key, val, default_opts)
    end
  end

  def add_translation(kind, src, dest, options)
    if is_glob?(src)
      dirs = expand_dir_glob(src)
    else
      dirs = [src]
    end
    dirs.each do |dirname|
      dirname = dirname.sub(%r{\A\./}, "").sub(%r{/\z}, "")
      @translate[kind].update({dirname => [dest, options]})
    end
  end

  def is_glob?(x)
    /(^|[^\\])[*?{\[]/.match(x)
  end

  def expand_dir_glob(src)
    Dir[src].select{|x| File.directory?(x)}
  end

  def clean_path(path)
    path.gsub(/\A\//, '').gsub(/\/+\Z/, '').squeeze("/")
  end

  def parse_command_line
    opts = OptionParser.new(nil, 24, ' ') { |opts|
      opts.banner = "Usage: setup.rb [options] [task]"

      opts.separator ""
      opts.separator "Tasks:"
      opts.separator "    config     configures paths"
      opts.separator "    show       shows paths"
      opts.separator "    setup      compiles ruby extentions and others XXX"
      opts.separator "    install    installs files"
      opts.separator "    test       runs unit tests"
      

      opts.separator ""
      opts.separator "Specific options:"

      opts.on "--prefix=PREFIX",
              "path prefix of target environment [#@prefix]" do |prefix|
        @prefix.replace clean_path(prefix)  # Shared!
      end

      opts.separator ""

      KINDS.each { |kind|
        opts.on "--#{kind}prefix=PREFIX",
                "path prefix for #{kind} files [#{@prefixes[kind]}]" do |prefix|
          @prefixes[kind] = clean_path(prefix)
        end
      }

      opts.separator ""

      KINDS.each { |kind|
        opts.on "--#{kind}dir=PREFIX",
                "directory for #{kind} files [#{@dirs[kind]}]" do |prefix|
          @dirs[kind] = clean_path(prefix)
        end
      }

      opts.separator ""

      KINDS.each { |kind|
        opts.on "--#{kind}=PREFIX",
                "absolute directory for #{kind} files [#{File.join(@prefixes[kind], @dirs[kind])}]" do |prefix|
          @prefixes[kind] = clean_path(prefix)
        end
      }

      opts.separator ""
      opts.separator "Predefined path configurations:"
      opts.on "--site", "install into site-local directories (default)" do
        @dirs.update SITE_DIRS
      end

      opts.on "--vendor", "install into distribution directories (for packagers)" do
        @dirs.update VENDOR_DIRS
      end
      
      opts.separator ""
      opts.separator "General options:"

      opts.on "--destdir=DESTDIR",
              "install all files relative to DESTDIR (/)" do |destdir|
        @options.destdir = destdir
      end

      opts.on "--dry-run", "only display what to do if given [#{@options.noop}]" do
        @options.noop = true
      end

      opts.on "--no-harm", "only display what to do if given" do
        @options.noop = true
      end

      opts.on "--[no-]verbose", "output messages verbosely [#{@options.verbose}]" do |verbose|
        @options.verbose = verbose
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    }

    opts.parse! ARGV

    if (ARGV - TASKS).empty?    # Only existing tasks?
      @tasks = ARGV
      @tasks = ["install"]  if @tasks.empty?
    else
      abort "Unknown task(s) #{(ARGV-TASKS).join ", "}."
    end
  end

  def run_tasks
    @tasks.each { |task| __send__ task }
  end
end

end # module Package

#XXX incomplete setup.rb support for the hooks
require 'rbconfig'
def config(x)
  Config::CONFIG[x]
end

#{{{ small example
if $0 == __FILE__
Package.setup("1.0") {
  name "Crypt::ISAAC"

  lib "crypt/ISAAC.rb"

  unit_test Dir["test/TC*.rb"]
}
end

# vim: sw=2 sts=2 et ts=8

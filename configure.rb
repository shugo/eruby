#!/usr/bin/env ruby

# Generated automatically using autoconf.rb version 0.2.4

require "mkmf"

$ac_help = ""
$ac_help += "  --enable-shared         build a shared library for eruby" "\n"
$ac_help += "  --with-charset=CHARSET  default charset is CHARSET [iso-8859-1]" "\n"

$ac_sed = {}
$ac_confdefs = {}
$ac_features = {}
$ac_packages = {}
  
def AC_SUBST(variable)
  $ac_sed[variable] = true
end

def AC_DEFINE(variable, value = 1)
  case value
  when true
    value = "1"
  when false
    value = "0"
  when String
    value = value.dump
  else
    value = value.inspect
  end
  $ac_confdefs[variable] = value
end

AC_GIVEN = Object.new
def AC_GIVEN.if_not_given
  # do nothing
end

AC_NOT_GIVEN = Object.new
def AC_NOT_GIVEN.if_not_given
  yield
end

def AC_ENABLE(feature, action = Proc.new)
  if $ac_features[feature]
    yield($ac_features[feature])
    return AC_GIVEN
  else
    return AC_NOT_GIVEN
  end
end

def AC_WITH(package, action = Proc.new)
  if $ac_packages[package]
    yield($ac_packages[package])
    return AC_GIVEN
  else
    return AC_NOT_GIVEN
  end
end

require 'ftools'

def AC_OUTPUT(*files)
  if $AC_LIST_HEADER
    $DEFS = "-DHAVE_CONFIG_H"
    AC_OUTPUT_HEADER($AC_LIST_HEADER)
  else
    $DEFS = $ac_confdefs.collect {|k, v| "-D#{k}=#{v}" }.join(" ")
  end
  for file in files
    print "creating ", file, "\n"
    open(File.join($srcdir, file + ".in")) do |fin|
      File.makedirs(File.dirname(file))
      open(file, "w") do |fout|
	while line = fin.gets
	  line.gsub!(/@([A-Za-z_]+)@/) do |s|
	    name = $1
	    if $ac_sed.key?(name)
	      eval("$" + name) #"
	    else
	      s
	    end
	  end
	  fout.print(line)
	end
      end
    end
  end
end

def AC_OUTPUT_HEADER(header)
  print "creating ", header, "\n"
  open(File.join($srcdir, header + ".in")) do |fin|
    open(header, "w") do |fout|
      while line = fin.gets
	line.sub!(/^(#define|#undef)\s+([A-Za-z_]+).*$/) do |s|
	  name = $2
	  if $ac_confdefs.key?(name)
	    val = $ac_confdefs[name]
	    "#define #{name} #{val}"
	  else
	    s
	  end
	end
	fout.print(line)
      end
    end
  end
  $ac_confdefs.clear
end

def AC_CONFIG_HEADER(header)
  $AC_LIST_HEADER = header
end

def AC_CHECK(feature)
  AC_MSG_CHECKING(feature)
  AC_MSG_RESULT(yield)
end

def AC_MSG_CHECKING(feature)
  print "checking #{feature}... "
  $stdout.flush
end

def AC_MSG_RESULT(result)
  case result
  when true
    result = "yes"
  when false, nil
    result = "no"
  end
  puts(result)
end

def AC_MSG_WARN(msg)
  $stderr.print("configure.rb: warning: ", msg, "\n")
end

def AC_MSG_ERROR(msg)
  $stderr.print("configure.rb: error: ", msg, "\n")
  exit(1)
end

def AC_CONFIG_AUX_DIR_DEFAULT
  AC_CONFIG_AUX_DIRS($srcdir, "#{$srcdir}/..",  "#{$srcdir}/../..")
end

def AC_CONFIG_AUX_DIRS(*dirs)
  for dir in dirs
    for prog in [ "install-rb", "install.rb" ]
      file = File.join(dir, prog)
      if File.file?(file); then
	$ac_aux_dir = dir
	$ac_install_rb = "#{file} -c"
	return
      end
    end
  end
end

def AC_PROG_INSTALL
  AC_MSG_CHECKING("for a BSD compatible install")
  $ac_cv_path_install = callcc { |c|
    for dir in ENV["PATH"].split(/:/)
      if %r'^(/|\./|/etc/.*|/usr/sbin/.*|/usr/etc/.*|/sbin/.*|/usr/afsws/bin/.*|/usr/ucb/.*)$' =~ dir + "/" # '
	next
      end
      for prog in [ "ginstall", "scoinst", "install" ]
	file = File.join(dir, prog)
	if File.file?(file)
	  if prog == "install" &&
	      `#{file} 2>&1` =~ /dspmsg/
	    # AIX install.  It has an incompatible calling convention.
	  else
	    c.call("#{file} -c")
	  end
	end
      end
    end
    unless $ac_install_rb
      AC_CONFIG_AUX_DIR_DEFAULT()
    end
    $ac_install_rb
  }
  $INSTALL = $ac_cv_path_install
  AC_MSG_RESULT($INSTALL)
  $INSTALL_PROGRAM ||= "$(INSTALL)"
  $INSTALL_SCRIPT ||= "$(INSTALL)"
  $INSTALL_DATA ||= "$(INSTALL) -m 644"
  $INSTALL_DLLIB ||= "$(INSTALL) -m 555"
  $INSTALL_DIR ||= "$(INSTALL) -d"
  AC_SUBST("INSTALL")
  AC_SUBST("INSTALL_PROGRAM")
  AC_SUBST("INSTALL_SCRIPT")
  AC_SUBST("INSTALL_DATA")
  AC_SUBST("INSTALL_DLLIB")
  AC_SUBST("INSTALL_DIR")
end

$stdout.sync = true

drive = File::PATH_SEPARATOR == ';' ? /\A\w:/ : /\A/
prefix = Regexp.new("\\A" + Regexp.quote(CONFIG["prefix"]))
$drive = CONFIG["prefix"] =~ drive ? $& : ''
$prefix = CONFIG["prefix"].sub(drive, '')
$exec_prefix = "$(prefix)"
$bindir = CONFIG["bindir"].sub(prefix, "$(exec_prefix)").sub(drive, '')
$datadir = CONFIG["datadir"].sub(prefix, "$(prefix)").sub(drive, '')
$libdir = CONFIG["libdir"].sub(prefix, "$(exec_prefix)").sub(drive, '')
$archdir = $archdir.sub(prefix, "$(prefix)").sub(drive, '')
$sitelibdir = $sitelibdir.sub(prefix, "$(prefix)").sub(drive, '')
$sitearchdir = $sitearchdir.sub(prefix, "$(prefix)").sub(drive, '')
$includedir = CONFIG["includedir"].sub(prefix, "$(prefix)").sub(drive, '')
$mandir = CONFIG["mandir"].sub(prefix, "$(prefix)").sub(drive, '')

$rubylibdir ||=
  $libdir + "/ruby/" + CONFIG["MAJOR"] + "." + CONFIG["MINOR"]

for option in ARGV
  if option =~ /^-.*?=(.*)/
    optarg = $1
  else
    optarg = nil
  end
  case option
  when /^--prefix/
    $prefix = optarg
  when /^--exec-prefix/
    $exec_prefix = optarg
  when /^--bindir/
    $bindir = optarg
  when /^--datadir/
    $datadir = optarg
  when /^--libdir/
    $libdir = optarg
  when /^--includedir/
    $includedir = optarg
  when /^--mandir/
    $mandir = optarg
  when /^--enable-([^=]+)/
    feature = $1
    if optarg.nil?
      optarg = "yes"
    end
    $ac_features[feature] = optarg
  when /^--with-([^=]+)/
    package = $1
    if optarg.nil?
      optarg = "yes"
    end
    $ac_packages[package] = optarg
  when "--help"
    print <<EOF
Usage: configure.rb [options]
Options: [defaults in brackets after descriptions]
Configuration:
  --help                  print this message
Directory and file names:
  --prefix=PREFIX         install architecture-independent files in PREFIX
                          [#{$prefix}]
  --exec-prefix=EPREFIX   install architecture-dependent files in EPREFIX
                          [same as prefix]
  --bindir=DIR            user executables in DIR [EPREFIX/bin]
  --libdir=DIR            object code libraries in DIR [EPREFIX/lib]
  --includedir=DIR        C header files in DIR [PREFIX/include]
  --datadir=DIR           read-only architecture-independent data in DIR
                          [PREFIX/share]
  --mandir=DIR            manual pages in DIR [PREFIX/man]
EOF
    if $ac_help.length > 0
      print "--enable and --with options recognized:\n"
      print $ac_help
    end
    exit(0)
  when /^-.*/
    AC_MSG_ERROR("#{option}: invalid option; use --help to show usage")
  end
end

$srcdir = File.expand_path(File.dirname($0))
$VPATH = ""

$arch = CONFIG["arch"]
$sitearch = CONFIG["sitearch"]
$ruby_version = Config::CONFIG["ruby_version"] ||
  CONFIG["MAJOR"] + "." + CONFIG["MINOR"]

$CC = CONFIG["CC"]
$AR = CONFIG["AR"]
$LD = "$(CC)"
$RANLIB = CONFIG["RANLIB"]

if not defined? CFLAGS
  CFLAGS = CONFIG["CFLAGS"]
end

if CFLAGS.index(CONFIG["CCDLFLAGS"])
  $CFLAGS = CFLAGS
else
  $CFLAGS = CFLAGS + " " + CONFIG["CCDLFLAGS"]
end
$LDFLAGS = CONFIG["LDFLAGS"]
if $LDFLAGS.to_s.empty? && /mswin32/ =~ RUBY_PLATFORM
  $LDFLAGS = "-link -incremental:no -pdb:none"
end
$LIBS = CONFIG["LIBS"]
$XLDFLAGS = CONFIG["XLDFLAGS"]
$XLDFLAGS.gsub!(/-L\./, "")
if /mswin32/ !~ RUBY_PLATFORM
  $XLDFLAGS += " -L$(libdir)"
elsif RUBY_VERSION >= "1.8"
  $XLDFLAGS += " #{CONFIG['LIBPATHFLAG'] % '$(libdir)'}"
end
$DLDFLAGS = CONFIG["DLDFLAGS"]
$LDSHARED = CONFIG["LDSHARED"]

$EXEEXT = CONFIG["EXEEXT"]
$DLEXT = CONFIG["DLEXT"]

$RUBY_INSTALL_NAME = CONFIG["RUBY_INSTALL_NAME"]
$RUBY_SHARED = (CONFIG["ENABLE_SHARED"] == "yes")
$LIBRUBYARG = CONFIG["LIBRUBYARG"]
if $RUBY_SHARED
  $LIBRUBYARG.gsub!(/-L\./, "")
else
  if RUBY_VERSION < "1.8" && RUBY_PLATFORM !~ /mswin32/
    $LIBRUBYARG = "$(hdrdir)/" + $LIBRUBYARG
  end
end
$LIBRUBY = CONFIG["LIBRUBY"]
$LIBRUBY_A = CONFIG["LIBRUBY_A"]
$RUBY_SO_NAME = CONFIG["RUBY_SO_NAME"]

case RUBY_PLATFORM
when /-aix/
  if $RUBY_SHARED
    $LIBRUBYARG = "-Wl,$(libdir)/" + CONFIG["LIBRUBY_SO"]
    $LIBRUBYARG.sub!(/\.so\.[.0-9]*$/, '.so')
    $XLDFLAGS = ""
  else
    $XLDFLAGS = "-Wl,-bE:$(topdir)/ruby.imp"
  end
  if $DLDFLAGS !~ /-Wl,/
    $LIBRUBYARG.gsub!(/-Wl,/, '')
    $XLDFLAGS.gsub!(/-Wl,/, '')
    $DLDFLAGS.gsub!(/-Wl,/, '')
  end
end

AC_SUBST("srcdir")
AC_SUBST("topdir")
AC_SUBST("hdrdir")
AC_SUBST("VPATH")

AC_SUBST("arch")
AC_SUBST("sitearch")
AC_SUBST("ruby_version")
AC_SUBST("drive")
AC_SUBST("prefix")
AC_SUBST("exec_prefix")
AC_SUBST("bindir")
AC_SUBST("datadir")
AC_SUBST("libdir")
AC_SUBST("rubylibdir")
AC_SUBST("archdir")
AC_SUBST("sitedir")
AC_SUBST("sitelibdir")
AC_SUBST("sitearchdir")
AC_SUBST("includedir")
AC_SUBST("mandir")

AC_SUBST("CC")
AC_SUBST("AR")
AC_SUBST("LD")
AC_SUBST("RANLIB")

AC_SUBST("CFLAGS")
AC_SUBST("DEFS")
AC_SUBST("LDFLAGS")
AC_SUBST("LIBS")
AC_SUBST("XLDFLAGS")
AC_SUBST("DLDFLAGS")
AC_SUBST("LDSHARED")

AC_SUBST("OBJEXT")
AC_SUBST("EXEEXT")
AC_SUBST("DLEXT")

AC_SUBST("RUBY_INSTALL_NAME")
AC_SUBST("LIBRUBYARG")
AC_SUBST("LIBRUBYARG_SHARED")
AC_SUBST("LIBRUBYARG_STATIC")
AC_SUBST("LIBRUBY")
AC_SUBST("LIBRUBY_A")
AC_SUBST("RUBY_SO_NAME")

$MAJOR, $MINOR, $TEENY =
  open(File.join($srcdir, "eruby.h")).grep(/ERUBY_VERSION/)[0].scan(/(\d+).(\d+).(\d+)/)[0]
$MAJOR_MINOR = format("%02d", ($MAJOR.to_i * 10 + $MINOR.to_i))
AC_SUBST("MAJOR")
AC_SUBST("MINOR")
AC_SUBST("TEENY")
AC_SUBST("MAJOR_MINOR")

AC_MSG_CHECKING("whether we are using gcc")
if $CC == "gcc" || `#{$CC} -v 2>&1` =~ /gcc/
  $using_gcc = true
  $CFLAGS += " -Wall"
else
  $using_gcc = false
end
AC_MSG_RESULT($using_gcc)

AC_MSG_CHECKING("Ruby version")
AC_MSG_RESULT(RUBY_VERSION)
if RUBY_VERSION < "1.6"
  AC_MSG_ERROR("eruby requires Ruby 1.6.x or later.")
end

AC_MSG_CHECKING("for default charset")
$DEFAULT_CHARSET = "iso-8859-1"
AC_WITH("charset") { |withval|
  $DEFAULT_CHARSET = withval
}
AC_MSG_RESULT($DEFAULT_CHARSET)
AC_DEFINE("ERUBY_DEFAULT_CHARSET", $DEFAULT_CHARSET)

AC_MSG_CHECKING("whether enable shared")
$ENABLE_SHARED = false
AC_ENABLE("shared") { |enableval|
  if enableval == "yes"
    if /-mswin32/ =~ RUBY_PLATFORM
      AC_MSG_ERROR("can't enable shared on mswin32")
    end
    $ENABLE_SHARED = true
  end
}
AC_MSG_RESULT($ENABLE_SHARED)

$LIBERUBY_A = "liberuby.a"
$LIBERUBY = "${LIBERUBY_A}"
$LIBERUBYARG="$(LIBERUBY_A)"

$LIBERUBY_SO = "liberuby.#{CONFIG['DLEXT']}.$(MAJOR).$(MINOR).$(TEENY)"
$LIBERUBY_ALIASES = "liberuby.#{CONFIG['DLEXT']}"

if $ENABLE_SHARED
  $LIBERUBY = "${LIBERUBY_SO}"
  $LIBERUBYARG = "-L. -leruby"
  case RUBY_PLATFORM
  when /-sunos4/
    $LIBERUBY_ALIASES = "liberuby.so.$(MAJOR).$(MINOR) liberuby.so"
  when /-linux/
    $DLDFLAGS = '-Wl,-soname,liberuby.so.$(MAJOR).$(MINOR)'
    $LIBERUBY_ALIASES = "liberuby.so.$(MAJOR).$(MINOR) liberuby.so"
  when /-(freebsd|netbsd)/
    $LIBERUBY_SO = "liberuby.so.$(MAJOR).$(MINOR)"
    if /elf/ =~ RUBY_PLATFORM || /-freebsd[3-9]/ =~ RUBY_PLATFORM
      $LIBERUBY_SO = "liberuby.so.$(MAJOR_MINOR)"
      $LIBERUBY_ALIASES = "liberuby.so"
    else
      $LIBERUBY_ALIASES = "liberuby.so.$(MAJOR) liberuby.so"
    end
  when /-solaris/
    $XLDFLAGS = "-R$(prefix)/lib"
  when /-hpux/
    $XLDFLAGS = "-Wl,+s,+b,$(prefix)/lib"
    $LIBERUBY_SO = "liberuby.sl.$(MAJOR).$(MINOR).$(TEENY)"
    $LIBERUBY_ALIASES = 'liberuby.sl.$(MAJOR).$(MINOR) liberuby.sl'
  when /-aix/
    $DLDFLAGS = '-Wl,-bE:eruby.imp'
    $LIBERUBYARG = "-L$(prefix)/lib -Wl,liberuby.so"
    if $DLDFLAGS !~ /-Wl,/
      $LIBRUBYARG.gsub!(/-Wl,/, '')
      $XLDFLAGS.gsub!(/-Wl,/, '')
      $DLDFLAGS.gsub!(/-Wl,/, '')
    end
    print "creating eruby.imp\n"
    ifile = open("eruby.imp", "w")
    begin
      ifile.write <<EOIF
#!
ruby_filename
eruby_mode
eruby_noheader
eruby_charset
EOIF
    ensure
      ifile.close
    end
  end
end

if /-mswin32/ =~ RUBY_PLATFORM
  $AR = "lib"
  $AROPT = "/out:$@"
  $LIBERUBY_A = "liberuby.lib"
  $LIBERUBY = "$(LIBERUBY_A)"
  $LIBRUBYARG.gsub!(Regexp.compile(Regexp.quote(CONFIG["RUBY_SO_NAME"] + ".lib")), CONFIG["LIBRUBY_A"])
  if /nmake/i =~ $make
    $LD = "$(CC)"
    $VPATH = "{$(VPATH)}"
  elsif RUBY_VERSION < "1.8"
    $LD = "env LIB='$(subst /,\\\\,$(libdir));$(LIB)' $(CC)"
  else
    $LD = "$(CC)"
  end
else
  $AROPT = "rcu $@"
end

AC_SUBST("LIBERUBY_A")
AC_SUBST("LIBERUBY")
AC_SUBST("LIBERUBYARG")
AC_SUBST("LIBERUBY_SO")
AC_SUBST("LIBERUBY_ALIASES")
AC_SUBST("AROPT")

$EXT_DLDFLAGS = CONFIG["DLDFLAGS"]
if $RUBY_SHARED || /mswin32/ =~ RUBY_PLATFORM
  $EXT_LIBRUBYARG = "$(LIBRUBYARG)"
else
  $EXT_LIBRUBYARG = ""
end

if /mswin32/ =~ RUBY_PLATFORM
  if RUBY_VERSION < "1.8"
  if /nmake/i =~ $make
      $MKERUBY = "set LIB=$(libdir:/=\\);$(LIB)\n\t"
  else
      $MKERUBY = "\tenv LIB='$(subst /,\\\\,$(LIBPATH)); $(EXT_LIBRUBYARG) $(LIB)' \\\n\t"
  end
    $MKERUBY << "$(LD) $(LDFLAGS) $(XLDFLAGS) $(OBJS) $(LIBERUBYARG) $(LIBRUBYARG) $(LIBS) -Fe$@"
  else
    $MKERUBY = "$(LD) $(OBJS) $(LIBERUBYARG) $(LIBRUBYARG) $(LIBS) -Fe$@ $(LDFLAGS) $(XLDFLAGS)"
  end
else
  $MKERUBY = "$(LD) $(LDFLAGS) $(XLDFLAGS) $(OBJS) $(LIBERUBYARG) $(LIBRUBYARG) $(LIBS) -o $@"
end

if $DLEXT != $OBJEXT
  if /mswin32/ =~ RUBY_PLATFORM
    if RUBY_VERSION < "1.8"
    if /nmake/i =~ $make
        $MKDLLIB = "set LIB=$(libdir:/=\\);$(LIB)\n\t"
      else
        $MKDLLIB = "\tenv LIB='$(subst /,\\\\,$(LIBPATH)); $(EXT_LIBRUBYARG) $(LIB)' \\\n\t"
      end
      $MKDLLIB << "$(LDSHARED) $(EXT_DLDFLAGS) -Fe$(DLLIB) $(EXT_OBJS) $(XLDFLAGS) $(LIBERUBYARG) $(EXT_LIBRUBYARG) $(LIBS) -link /INCREMENTAL:no /EXPORT:Init_eruby"
    else
      $DEFFILE = 'eruby.def'
      File.open($DEFFILE, 'w') do |deffile|
        deffile.puts "EXPORTS"
        deffile.puts "Init_eruby"
    end
      $MKDLLIB = "$(LDSHARED) $(EXT_OBJS) $(LIBS) $(LIBERUBYARG) $(EXT_LIBRUBYARG) -Fe$(DLLIB) $(EXT_DLDFLAGS) $(XLDFLAGS)"
  end
  else
    $MKDLLIB = "$(LDSHARED) $(EXT_DLDFLAGS) -o $(DLLIB) $(EXT_OBJS) $(XLDFLAGS) $(LIBERUBYARG) $(EXT_LIBRUBYARG) $(LIBS)"
  end
else
  case RUBY_PLATFORM
  when "m68k-human"
    $MKDLLIB = "ar cru $(DLLIB) $(EXT_OBJS) $(LIBS)"
  else
    $MKDLLIB = "ld $(DLL_DLDFLAGS) -r -o $(DLLIB) $(EXT_OBJS) $(LIBERUBYARG) $(EXT_LIBRUBYARG) $(LIBS)"
  end
end

AC_SUBST("EXT_DLDFLAGS")
AC_SUBST("EXT_LIBRUBYARG")
AC_SUBST("MKERUBY")
AC_SUBST("MKDLLIB")
AC_SUBST("DEFFILE")

AC_CONFIG_HEADER("config.h")
AC_OUTPUT("Makefile")

# Local variables:
# mode: Ruby
# tab-width: 8
# End:

=begin

= NAME

eruby - Embedded Ruby Language

= SYNOPSIS

eruby [options] [inputfile]

= DESCRIPTION

eruby interprets a Ruby code embedded text file. For example, eruby
enables you to embed a Ruby code to a HTML file.

A Ruby block starts with `<%' and ends with `%>'. eRuby replaces
the block with its output.

If `<%' is followed by `=', eRuby replaces the block with a value
of the block.

If `<%' is followed by `#', the block is ignored as a comment.

= OPTIONS

:-d, --debug
  set debugging flags (set $DEBUG to true)
:-Kkcode
  specifies KANJI (Japanese) code-set
:-Mmode
  specifies runtime mode
    f: filter mode
    c: CGI mode
    n: NPH-CGI mode
:-C charset
  specifies charset parameter for Content-Type
:-n, --noheader
  disables CGI header output
:-v, --verbose
  enables verbose mode
:--version 
  print version information and exit

= AUTHOR

Shugo Maeda <shugo@ruby-lang.org>

=end

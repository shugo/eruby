require "eruby"

if filename = ARGV.shift
  file = open(filename)
else
  filename = "-"
  file = STDIN
end
compiler = ERuby::Compiler.new
code = compiler.compile_file(file)
eval(code, nil, filename)


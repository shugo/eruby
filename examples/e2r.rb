require "eruby"

if filename = ARGV.shift
  file = open(filename)
else
  file = STDIN
end
compiler = ERuby::Compiler.new
print compiler.compile_file(file)

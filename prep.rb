require './vequals'

# Turns a tracepoint into a line of ruby code (as a string)

# TODO: handle more literals

  

# code = [
#   "3 => foobar",
#   "     ‖",
#   "c = bizbaz",
# ].each_with_index { |line, i| process_line(line, i+1) }

# trace = TracePoint.new(:line) do |tp|
#   puts "line=#{tp.lineno}: " + get_line(tp)
#   process_line(get_line(tp), tp.lineno, tp.binding)
#   puts ""
# end

# trace.enable
Vequals.enable(logging: true)

# "foo" => bar
#           ‖
#         aaaaa
#         ‖
# c   =   b

# 3 => fooooooobaaaaar
#       ‖  ‖  ‖  ‖  ‖
#       d  e  f  g  h

4
‖
x

# puts "done"
# # puts "result=#{result}"
# puts "b=#{b}"
# puts "e=#{e}"

puts c == "foo"
puts b == "foo"
puts aaaaa == "foo"
# puts "x=#{x}"

# puts "done"
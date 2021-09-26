require './vequals_v2'

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
Vequals.enable(logging: false)

"foo" => bar
          ‖
        aaaaa
        ‖
c   =   b
puts c == "foo"
puts b == "foo"
puts aaaaa == "foo"

3 => fooooooobaaaaar
      ‖  ‖  ‖  ‖  ‖
      d  e  f  g  h
puts "h=#{h}"
puts "e=#{e}"

7
‖
x

puts "x = #{x}"


# 3 => foobar => y
#        ‖       ‖
#        x       z

# puts "done"
# # puts "result=#{result}"
# puts "b=#{b}"
# puts "e=#{e}"
# puts "x=#{x}"
# puts "z=#{z}"

# puts c == "foo"
# puts b == "foo"
# puts aaaaa == "foo"
# puts "x=#{x}"

# puts "done"
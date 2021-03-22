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
Vequals.enable

"foo" => bar
          ‖
        aaaaa
        ‖
c   =   b
‖
d => e => f => g
               ‖
              result

3 => fooooooobaaaaar
        ‖  ‖ 
        a  b 

  puts "done"
  puts "result=#{result}"
puts "b=#{b}"
puts "a=#{a}"

# puts "done"
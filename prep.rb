require 'ripper'

def ‖(*args)
end

# Turns a tracepoint into a line of ruby code (as a string)
def get_line(tp)
  File.readlines(tp.path)[tp.lineno - 1]
end

# TODO: handle more literals
def literalize(value)
  if value.is_a? String
    '"' + value + '"'
  else
    value
  end

end

$exp_ranges_by_line = []
$vequals_to_process = []
  
def process_line(line, lineno, line_binding)
  puts "Starting line with vequals to process:#{$vequals_to_process}"

  # Lex the current line
  lexed = Ripper.lex(line)
  puts "Lexed as #{lexed}"
  exp_ranges = []

  previous_line_vequals_to_process = $vequals_to_process
  $vequals_to_process = []

  # Ignore the column field in the provided by the lexer, since it doesn't
  # properly take into account multibyte codepoints (ie anything other than
  # ascii). For example, `Î` takes up two bytes and so anything after it will
  # have its column offset by 2, which screws up line position matching.
  column = 0

  # Figure out where each token is on the line
  lexed.each do |_, event, value, state|
    case event
    when :on_tstring_content
      # yeah, this breaks string interpolation
      exp_ranges << ["'" + value + "'", (column..(column + value.length))]
    when :on_ident
      if value == "‖"
        next unless previous_line_exp_ranges = $exp_ranges_by_line.last
        exp_range_above = previous_line_exp_ranges.find do |exp_range|
          exp_range[1].include?(column)
        end

        # puts "About to eval '#{exp_range_above[0]}'"
        eval_result = line_binding.eval(exp_range_above[0])
        # puts "Got eval result: '#{eval_result}'"
        $vequals_to_process << {
          # Evaluate in the context of the vequals line
          value: eval_result,
          column: column,
          lineno: lineno
        }
      else
        puts "considering ident #{value}, column #{column}, length: #{value.length}"

        # Since this is a variable (or at least an identifier), let's see if
        # there is a vequals directly above it.
        matching_vequals_entry = previous_line_vequals_to_process.find do |vequals_entry|
          (column..(column + value.length)).include?(vequals_entry[:column])
        end

        # If there is, define the variable we're looking at.
        if matching_vequals_entry
          puts "Found matching vequals: #{matching_vequals_entry}"
          # if it already exists, just set it
          if line_binding.local_variable_defined?(value.to_sym)
            line_binding.local_variable_set(value.to_sym, matching_vequals_entry[:value])
          else
            # If not, we need to create a new local variable.

            # You can't inject new local variables into a binding (only update
            # existing ones). So instead, we'll take the coward's path and just
            # define a method with that name. This works because the def goes up
            # one scope level. This makes this "variable" in scope in more places
            # than it should be, but I won't tell if you don't.
            new_value = literalize(matching_vequals_entry[:value])
            puts "About to run 'def #{value}(*args) = #{new_value}'"
            line_binding.eval("def #{value}(*args) = #{new_value}")
            puts "/ran"
          end
        end

        exp_ranges << [value, (column..(column + value.length))]
      end
    when :on_int
      exp_ranges << [value, (column..(column + value.length))]
    else
      # puts "Skipping #{event}"
      # Not an expression we care about
    end

    column += value.length
  end

  # Add this on to the end and pop the oldest line off the front. TODO: real
  # queue. We only need the last 2 lines because that's how far up we want to
  # look for the ||.
  # puts "End of line.  exp_ranges = #{exp_ranges}"
  $exp_ranges_by_line << exp_ranges
  $exp_ranges_by_line.shift if $exp_ranges_by_line.length > 2

end

# code = [
#   "3 => foobar",
#   "     ‖",
#   "c = bizbaz",
# ].each_with_index { |line, i| process_line(line, i+1) }

trace = TracePoint.new(:line) do |tp|
  puts "line=#{tp.lineno}: " + get_line(tp)
  process_line(get_line(tp), tp.lineno, tp.binding)
  puts ""
end

trace.enable do

"foo" => bar
           ‖
         aaaaa
         ‖
c   =    b
‖
d => e => f => g
               ‖
              result

# 3 => fooooooobaaaaar
#       ‖  ‖ 
#       a  b 

puts "done"
puts "result=#{result}"
# puts "b=#{b}" # prints "foo"
# puts "a=#{a}" # prints "foo"

end
# puts "done"
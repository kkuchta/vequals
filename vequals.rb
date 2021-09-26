require 'ripper'

class Vequals
  def self.enable(logging: false, &block)
    vequals = Vequals.new
    vequals.enable(logging: logging, &block)
  end

  def enable(logging: false, &block)
    @logging = logging

    trace = TracePoint.new(:line) do |tp|
      line = File.readlines(tp.path)[tp.lineno - 1]
      log "line=#{tp.lineno}: " + line
      process_line(line, tp.lineno, tp.binding)
      log ""
    end

    @exp_ranges_by_line = []
    @vequals_to_process = []

    # TODO: use refinements to limit scope
    Object.send(:define_method, :‖) {|*_|}

    if block_given?
      trace.enable(&block) 
    else
      trace.enable
    end
  end 

  # You can't drop a breakpoint into code that's running inside a tracepoint
  # callback (since tracepoint is used to implement the breakpoints), so we
  # need to rely on logging a lot.
  def log(*args)
    puts *args if @logging
  end

  # Turn a literal value like the string "foo" and turn it into a string that,
  # when evaled, produces that literal value.
  # // TODO: handle more types (eg arrays)
  def literalize(value)
    if value.is_a? String
      '"' + value + '"'
    else
      value
    end
  end

  def process_line_for_vequals(line, lineno, line_binding)
    previous_line_vequals_to_process = @vequals_to_process
    @vequals_to_process = []
  
    # Ignore the column field in the provided by the lexer, since it doesn't
    # properly take into account multibyte codepoints (ie anything other than
    # ascii). For example, `Î` takes up two bytes and so anything after it will
    # have its column offset by 2, which screws up line position matching.
    column = 0

    lexed = Ripper.lex(line)
    log "Lexed as #{lexed}"

    # Look through this line for any vequals
    lexed.each do |_positions, type, token, state|
      if event == :on_ident && value == "‖"
        previous_line_exp_ranges = get_exp_ranges(line - 1)
        @vequals_to_process << {
          # Evaluate in the context of the vequals line
          value: eval_result,
          column: column,
          lineno: lineno
        }
      end
    end
  end

  # Yeah, we should break this up, but it's not worth it for a project like
  # this nonsense.
  def process_line(line, lineno, line_binding)
    log "Starting line with vequals to process:#{@vequals_to_process}"
  
    # Lex the current line
    lexed = Ripper.lex(line)
    log "Lexed as #{lexed}"
    exp_ranges = []
  
    previous_line_vequals_to_process = @vequals_to_process
    @vequals_to_process = []
  
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
          # Ignore if we're on the first line (?)
          next unless previous_line_exp_ranges = @exp_ranges_by_line.last

          exp_range_above = previous_line_exp_ranges.find do |exp_range|
            exp_range[1].include?(column)
          end
  
          # puts "About to eval '#{exp_range_above[0]}'"
          eval_result = line_binding.eval(exp_range_above[0])
          # puts "Got eval result: '#{eval_result}'"
          @vequals_to_process << {
            # Evaluate in the context of the vequals line
            value: eval_result,
            column: column,
            lineno: lineno
          }
        else
          # We're lookinng at an identifier (variable name)
          log "considering ident #{value}, column #{column}, length: #{value.length}"
  
          # Since this is a variable (or at least an identifier), let's see if
          # there is a vequals directly above it.
          matching_vequals_entry = previous_line_vequals_to_process.find do |vequals_entry|
            (column..(column + value.length)).include?(vequals_entry[:column])
          end
  
          # If there is, define the variable we're looking at.
          if matching_vequals_entry
            log "Found matching vequals: #{matching_vequals_entry}"
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
              assignment_code = "def #{value}(*args) = #{new_value}"
              log "About to run '#{assignment_code}'"
              line_binding.eval(assignment_code)
            end
          else
            puts "No matching vequals entry"
          end
  
          exp_ranges << [value, (column..(column + value.length))]
        end
      when :on_int
        exp_ranges << [value, (column..(column + value.length))]
      else
        # log "Skipping #{event}"
        # Not an expression we care about
      end
  
      column += value.length
    end
  
    # Add this on to the end and pop the oldest line off the front. TODO: real
    # queue. We only need the last 2 lines because that's how far up we want to
    # look for the ||.
    @exp_ranges_by_line << exp_ranges
    @exp_ranges_by_line.shift if @exp_ranges_by_line.length > 2
  end
end
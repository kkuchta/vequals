require 'ripper'

class Vequals
  def self.enable(logging: false, &block)
    vequals = Vequals.new
    vequals.enable(logging: logging, &block)
  end

  def enable(logging: false, &block)
    @logging = logging
    @vequels_by_line = {}

    trace = TracePoint.new(:line) do |tp|
      line = File.readlines(tp.path)[tp.lineno - 1]
      log "line=#{tp.lineno}: " + line
      check_for_vequels(line, tp)
      process_any_vequels_from_previous_line(line, tp)
      log "vequels_by_line=#{@vequels_by_line}"
      log ""
    end

    # TODO: use refinements to limit scope
    Object.define_method(:‖) {|*_|}

    if block_given?
      trace.enable(&block) 
    else
      trace.enable
    end
  end 

  def check_for_vequels(line, tp)
    @vequels_by_line[tp.lineno] = []
  
    # Ignore the column field in the provided by the lexer, since it doesn't
    # properly take into account multibyte codepoints (ie anything other than
    # ascii). For example, `Î` takes up two bytes and so anything after it will
    # have its column offset by 2, which screws up line position matching.
    column = 0

    lexed = Ripper.lex(line)
    log "Lexed as #{lexed}"

    # Look through this line for any vequals
    lexed.each do |_positions, type, token, state|
      if type == :on_ident && token == "‖"

        # Get the expression above this vequels
        exp_above = get_exp(tp.path, tp.lineno - 1, column)

        # Get the value of that expression
        eval_result = tp.binding.eval(exp_above)

        @vequels_by_line[tp.lineno] << {
          value_to_assign: eval_result,
          column: column
        }
      end
      column += token.length
    end
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

  def process_any_vequels_from_previous_line(line, tp)
    # Skip if this is the first line since there can be no vequals above it.
    return unless vequels_to_process = @vequels_by_line[tp.lineno-1]

    lexed = Ripper.lex(line)

    column = 0
    lexed.each do |_positions, type, token, state|
      if type == :on_ident
        # is there a vequels above me?
        matching_vequals_entry = vequels_to_process.find do |vequals_entry|
          (column..(column + token.length)).include?(vequals_entry[:column])
        end
        if matching_vequals_entry
          log "Found vequals above #{token} with value #{matching_vequals_entry[:exp_above]}"
          value_to_assign = matching_vequals_entry[:value_to_assign]

          # if it already exists, just set it
          if tp.binding.local_variable_defined?(token.to_sym)
            tp.binding.local_variable_set(token.to_sym, value_to_assign)
          else
            # If not, we need to create a new local variable.

            # You can't inject new local variables into a binding (only update
            # existing ones). So instead, we'll take the coward's path and just
            # define a method with that name. This works because the def goes up
            # one scope level. This makes this "variable" in scope in more places
            # than it should be, but I won't tell if you don't.
            value_as_literal = literalize(value_to_assign)
            assignment_code = "def #{token}(*args) = #{value_as_literal}"
            log "About to run '#{assignment_code}'"
            tp.binding.eval(assignment_code)
          end
        end
      end
      column += token.length
    end
  end

  def get_exp(path, lineno, column)
    line = File.readlines(path)[lineno - 1]
    exp_ranges = get_exp_ranges(line)
    exp_range = exp_ranges.find do |exp_range|
      exp_range[1].include?(column)
    end
    exp_range[0]
  end

  def get_exp_ranges(line)
    lexed = Ripper.lex(line)
    column = 0
    exp_ranges = []
    lexed.each do |_positions, type, token, state|
      case type
      when :on_tstring_content
        exp_ranges << ["'" + token + "'", (column..(column + token.length))]
      when :on_ident
        exp_ranges << [token, (column..(column + token.length))]
      when :on_int
        exp_ranges << [token, (column..(column + token.length))]
      else
        # Skipping type
        # Ints, strings, and identifiers are the only expressions that exist
      end
      column += token.length
    end
    exp_ranges
  end

  def log(*args)
    puts *args if @logging
  end
end
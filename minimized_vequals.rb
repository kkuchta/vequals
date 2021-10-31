require 'ripper'

# This is a minimized version of vequals - the one shown in my rubyconf talk on
# the subject.  I've stripped out a lot of spacing, comments, and other niceties
# to keep it small enough to fit on slides.  Check out vequals.rb for a more
# readable version.
class Vequals
  def enable
    @vequals_by_line = {}
    trace = TracePoint.new(:line) do |tp|
      line = File.readlines(tp.path)[tp.lineno - 1]
      check_for_vequals(line, tp)
      process_any_vequals_from_previous_line(line, tp)
    end
    Object.define_method(:‖) {|*_|}
    trace.enable
  end 

  def self.enable()
    Vequals.new.enable
  end

  def check_for_vequals(line, tp)
    @vequals_by_line[tp.lineno] = []
    column = 0
    lexed = Ripper.lex(line)

    lexed.each do |_positions, type, token, state|
      if type == :on_ident && token == "‖"
        exp_above = get_exp(tp.path, tp.lineno - 1, column)
        eval_result = tp.binding.eval(exp_above)

        @vequals_by_line[tp.lineno] << {
          value_to_assign: eval_result,
          column: column
        }
      end
      column += token.length
    end
  end

  def process_any_vequals_from_previous_line(line, tp)
    return unless vequals_to_process = @vequals_by_line[tp.lineno-1]
    lexed = Ripper.lex(line)
    column = 0
    lexed.each do |_positions, type, token, state|
      if type == :on_ident
        matching_vequals_entry = vequals_to_process.find do |vequals_entry|
          (column..(column + token.length)).include?(vequals_entry[:column])
        end
        if matching_vequals_entry
          value_to_assign = matching_vequals_entry[:value_to_assign]
          if tp.binding.local_variable_defined?(token.to_sym)
            tp.binding.local_variable_set(token.to_sym, value_to_assign)
          else
            value_as_literal = literalize(value_to_assign)
            assignment_code = "def #{token}(*args) = #{value_as_literal}"
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
      end
      column += token.length
    end
    exp_ranges
  end

  def literalize(value)
    if value.is_a? String
      '"' + value + '"'
    else
      value
    end
  end
end
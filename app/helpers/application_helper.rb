module ApplicationHelper
  def is_float?(str)
    true if Float(str) rescue false
  end
  def is_pair_of_floats?(line)
    if is_float?(line.split[0]) && is_float?(line.split[1])
      return [line.split[0].to_f, line.split[1].to_f]
    end
    return false
  end

end

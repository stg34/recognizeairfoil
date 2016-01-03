module AirfoilChecker

  class AirfoilUncorrectableError < StandardError
    attr_reader :line_num
    def initialize(opts)
      @msg = opts[:msg]
      @line_num = opts[:line_num]
      @line = opts[:line]
    end
  end

  class ErrorPointsConsistency < AirfoilUncorrectableError
    def message
      @msg
    end
  end

  class ErrorIncreaseDecrease < AirfoilUncorrectableError
    def message
      'X coordinates must decrease for top line and increase for bottom line'# + @msg.to_s
    end
  end

  class ErrorPointsCount < AirfoilUncorrectableError
    def message
      'At least 10 points for top surface and 10 points for bottom surface are required'
    end
  end

  class ErrorXRange < StandardError
    def message
      'X coordinates must be in range 0...1'
    end
  end

  class ErrorSameTopXCoordinate < StandardError
    def message
      'Top line should not contain same x coordinates'
    end
  end

  class ErrorSameBottomXCoordinate < StandardError
    def message
      'Bottom line should not contain same x coordinates'
    end
  end

  class ErrorClosure < StandardError
    def message
      'Unclosed contour'
    end
  end

  class ErrorBaseLine < StandardError
    def message
      'Base line error'
    end

  end

  class Coord
    attr_accessor :x
    attr_accessor :y
    attr_accessor :message
    attr_reader :line
    def initialize(x, y, line)
      @x = x
      @y = y
      @line = line
      @message = nil
    end
  end

  class Airfoil
    attr_reader :top
    attr_reader :bottom
    def initialize(top, bottom)
      @top = []
      top.each do |c|
        @top << Coord.new(c.x, c.y, c.line)
      end

      @bottom = []
      bottom.each do |c|
        @bottom << Coord.new(c.x, c.y, c.line)
      end
    end

    def thickness
      top.map(&:y).max - bottom.map(&:y).min
    end

    def interpolate(x, c1, c2)
      if c1.nil?
        return c2.x
      end
      if c2.nil?
        return c1.x
      end
      k = (c2.y.to_f - c1.y)/(c2.x - c1.x)
      return k * (x - c1.x) + c1.y
    end

    def get_top_y(x)
      idx = top.find_index{|c| c.x <= x} || top.size
      return interpolate(x, top[idx], top[idx-1])
    end

    def get_bottom_y(x)
      idx = bottom.find_index{|c| c.x >= x} || 0
      return interpolate(x, bottom[idx], bottom[idx-1])
    end

    def shift(dy)
      @top.map! do |c|
        Coord.new(c.x, c.y + dy, c.line)
      end

      @bottom.map! do |c|
        Coord.new(c.x, c.y + dy, c.line)
      end
    end

    def rotate(angle)
      @top.map! do |c|
        x = c.x
        y = c.y
        x1 = x*Math.cos(angle) - y*Math.sin(angle)
        y1 = x*Math.sin(angle) + y*Math.cos(angle)
        Coord.new(x1, y1, c.line)
      end

      @bottom.map! do |c|
        x = c.x
        y = c.y
        x1 = x*Math.cos(angle) - y*Math.sin(angle)
        y1 = x*Math.sin(angle) + y*Math.cos(angle)
        Coord.new(x1, y1, c.line)
      end
    end

    def compare(foil, opts)
      n = 10
      xx = (0.upto n-1).to_a.map{|e| e/n.to_f}
      s = []
      a0 = opts[:angles][0]
      a1 = opts[:angles][1]
      step = opts[:angles][2]

      a = a0

      ytyb = xx.map{|x| [get_top_y(x), foil.get_top_y(x), get_bottom_y(x), foil.get_bottom_y(x)]}

      # ftm = ytyb.map{|yy| yy[1]}.sum/n
      # fbm = ytyb.map{|yy| yy[3]}.sum/n
      fm = ytyb.map{|yy| yy[1] + yy[3]}.sum/(2*n)

      ftm = fm
      fbm = fm

      ytyb.map! do |yy|
        [
            yy[0],
            yy[1] - ftm,
            yy[2],
            yy[3] - fbm
        ]
      end

      while a <= a1
        aa = a * Math::PI/180
        st = 0
        sb = 0
        ytyb_rotated = ytyb.map.with_index do |yy, i|
          x = xx[i]
          [
              x*Math.sin(aa) + yy[0], #*Math.cos(aa),
              yy[1],
              x*Math.sin(aa) + yy[2], #*Math.cos(aa),
              yy[3]
          ]
        end

        #tm = ytyb_rotated.map{|yy| yy[0]}.sum/n
        #bm = ytyb_rotated.map{|yy| yy[2]}.sum/n
        m = ytyb_rotated.map{|yy| yy[0] + yy[2]}.sum/(2*n)
        tm = m
        bm = m
        ytyb_rotated.map!{|yy| [yy[0] - tm, yy[1], yy[2] - bm, yy[3]]}

        ds = 0
        ytyb_rotated.each do |yy|
          st += (yy[0] - yy[1])**2
          sb += (yy[2] - yy[3])**2
          ds =+ (st + sb)
        end

        sum = ytyb_rotated.map{|yy| yy.sum}.sum

        debug = {
           ds: ds,
           sum: sum,
           shift: m - fm,
           st: st,
           sb:sb,
           mean: m,
           # top_mean: tm,
           # bottom_mean: bm,
           f_mean: fm,
           # f_top_mean: ftm,
           # f_bottom_mean: fbm
        }

        s << [ds, a, debug]
        a += step
      end

      return s.min{|a, b| a[0]<=>b[0]}
    end

  end

  class Checker

    E = 0.00001

    attr_reader :coords
    attr_reader :name
    attr_reader :lines
    attr_reader :raw
    attr_accessor :errors
    attr_accessor :corrections

    def initialize(raw)
      @raw = raw
      @lines = raw.lines
      @coords = []
      @errors = []
      @corrections = []
    end

    def uncorrectable_errors
      errors.select{|e| [ErrorPointsConsistency, ErrorIncreaseDecrease].include?(e.class)}
    end

    def read_file(dir, file_name)
      file_text = File.read(dir.to_s + '/' + file_name)
      @raw = file_text
      @lines = file_text.lines
      @file_name = file_name
    end

    def write_file(dir, file_name)
      if errors.empty?
        File.open(dir + '/' + file_name, 'w') do |f|
          f.write("#{name}\n")
          coords.each do |c|
            f.write("%10.6f   %10.6f\n" % [c.x, c.y])
          end
          corrections.each do |c|
            f.write("#{c}\n")
          end
        end
      else
        File.open(dir + '/' + file_name, 'w') do |f|
          lines.each do |l|
            f.write(l)
          end
          errors.each do |e|
            f.write("#{e.message}. Line: #{e.line_num}\n")
          end
        end

      end
    end

    def is_pair_of_floats?(line)
      if is_float?(line.split[0]) && is_float?(line.split[1])
        return [line.split[0].to_f, line.split[1].to_f]
      end
      return false
    end

    def is_float?(str)
      true if Float(str) rescue false
    end

    def is_name?(line)
      /[a-zA-Z]/ =~ line
    end

    def get_name
      if is_pair_of_floats?(lines[0]) || lines[0].strip.empty?
        @name = @file_name || 'No name'
      else
        @name = lines[0].strip
      end
    end

    def check_points_consistency

      lines_type = lines.map.with_index do |line, i|
        if line.strip.empty?
          type = 'empty'
        elsif is_pair_of_floats?(line)
          type = 'pair'
        else
          type = 'text'
        end
        {type: type, num: i}
      end

      lines_type.delete_if{|lt| lt[:type] == 'empty'}

      # lines_type = [{type: 'text', num: 1}, {type: 'pair'}, {type: 'pair'}, {type: 'text'}, {type: 'pair'}]
      if lines_type.chunk{|n| n[:type]}.to_a.map{|e| e[1].first}.count{|e| e[:type]} == 0
        raise ErrorPointsConsistency.new(line_num: lines.size + 1, msg: 'Coordinates not found')
      end

      grouped = lines_type.chunk{|n| n[:type]}.map{|e| e[1].first}
      # grouped = [{:type=>"text", num: 1}, {:type=>"pair"}, {:type=>"text"}, {:type=>"pair"}]

      second_block = grouped.select{|e| e[:type] == 'pair'}.second
      if second_block
        raise ErrorPointsConsistency.new(line_num: second_block[:num], msg: 'First line must be a name of airfoil or a pair of numbers. Rest of lines must be a pair of numbers or empty lines')
      end

    end

    def check_points_count
      if bottom.size < 10 || top.size < 10
        raise ErrorPointsCount.new({})
      end
    end

    def check_total_points_count
      if lines.count{|l| is_pair_of_floats?(l)} < 20
        raise ErrorPointsCount.new({})
      end
    end

    def get_coordinates
      ll = lines.select{|line| is_pair_of_floats?(line)}
      @coords = ll.map.with_index{|pair, i| Coord.new(*pair.split.map(&:to_f), i + 1)}
    end

    def check_x_range
      xx = coords.map(&:x)
      if xx.min.abs > E || (1.0-xx.max).abs > E
        raise ErrorXRange
      end
    end

    def fix_x_range
      xx = coords.map(&:x)
      min_x = xx.min
      max_x = xx.max

      delta = min_x
      k = 1/(max_x - min_x)

      if min_x != 0 || max_x != 1.0
        coords.map! do |c|
          x = (c.x - delta)*k
          y = c.y*k
          Coord.new(x, y, c.line)
        end
      end
    end

    def check_increase_decrease
      prev_sign = -1
      coords[1..-1].each_index do |i|
        xi = coords[i].x
        xi1 = coords[i+1].x
        x_sign = xi1 <=> xi
        if i == 0 && x_sign != -1
          raise ErrorIncreaseDecrease.new(line_num: coords[i + 1].line + 1, msg: coords[i + 1].x)
        end
        if prev_sign == -1
          if x_sign == prev_sign
            next
          else
            prev_sign = x_sign
          end
        elsif prev_sign == 0
          if x_sign != 1
            raise ErrorIncreaseDecrease.new(line_num: coords[i + 1].line, msg: coords[i + 1].x)
          else
            prev_sign = 1
          end
        else
          if x_sign != prev_sign
            raise ErrorIncreaseDecrease.new(line_num: coords[i + 1].line, msg: coords[i + 1].x)
          end
        end
      end
      if prev_sign != 1
        raise ErrorIncreaseDecrease.new(line_num: coords.last.line + 1, msg: coords.last.x)
      end
    end

    def thickness
      top.map(&:y).max - bottom.map(&:y).min
    end

    def get_top_bottom
      x_coords = coords.map(&:x)
      @inc_dec = x_coords[1..-1].map.with_index{|_, i| x_coords[i+1]-x_coords[i] <=> 0}
      @top_bottom_border_idx = @inc_dec.find_index{|id| id > 0}
      raise 'Error' unless @top_bottom_border_idx
    end

    def fix_top_same_points
      top[1..-1].each_index do |i|
        if top[i].x == top[i+1].x
          top[i].x = top[i].x + E
        end
      end
    end

    def fix_bottom_same_points
      bottom[1..-1].each_index do |i|
        if bottom[i].x == bottom[i+1].x
          bottom[i+1].x = bottom[i+1].x + E
        end
      end
    end

    def bottom
      if @inc_dec.include? 0
        return @coords[@top_bottom_border_idx..-1]
      else
        # Одна точка входит в обе линии и в верхнюю и в нижнюю
        return @coords[@top_bottom_border_idx..-1]
      end
    end

    def top
      if @inc_dec.include? 0
        return @coords[0...@top_bottom_border_idx]
      else
        # Одна точка входит в обе линии и в верхнюю и в нижнюю
        return @coords[0..@top_bottom_border_idx]
      end
    end


    def top_as_str
      top.map{|c| "#{c.x},#{c.y}"}.join(';')
    end

    def bottom_as_str
      bottom.map{|c| "#{c.x},#{c.y}"}.join(';')
    end

    def check_closure
      if (@coords.first.x != @coords.last.x) || (@coords.first.y != @coords.last.y)
        raise ErrorClosure
      end
    end

    def fix_closure

      first = @coords.first
      last = @coords.last

      if (first.x != last.x) || (first.y != last.y)
        if first.x == last.x
          mean_y = (first.y + last.y)/2
          @coords[-1] = Coord.new(last.x - E, last.y, last.line)
          @coords[0] = Coord.new(first.x - E, first.y, first.line)
          @coords.push(Coord.new(1.0, mean_y, -1))
          @coords.insert(0, Coord.new(1.0, mean_y, -1))
        elsif @coords.first.x < @coords.last.x
          @coords.insert(0, @coords.last)
        elsif @coords.first.x > @coords.last.x
          @coords.push(@coords.first)
        end
      end

    end

    def check_base_line
      if top.first.y.abs > E || top.last.y.abs > E
        raise ErrorBaseLine
      end

      if bottom.first.y.abs > E || bottom.last.y.abs > E
        raise ErrorBaseLine
      end
    end

    def rotate(angle)
      @coords.map! do |c|
        x = c.x
        y = c.y
        x1 = x*Math.cos(angle) - y*Math.sin(angle)
        y1 = x*Math.sin(angle) + y*Math.cos(angle)
        Coord.new(x1, y1, c.line)
      end
    end

    def fix_base_line
      first_shift = top.first.y
      last_shift = top.last.y
      d = last_shift - first_shift

      @coords.map!{|c| Coord.new(c.x, c.y - last_shift, c.line)}

      alpha = Math.atan(d)
      rotate(alpha)
    end

    def raw_coords
      coords_with_line_num = []
      lines.each_with_index do |line, i|
        if is_float?(line.split[0]) && is_float?(line.split[1])
          coords_with_line_num << [line.split[0].to_f, line.split[1].to_f, i]
        end
      end
      return coords_with_line_num
    end


    def check
      @data_correct = false
      tries = 0

      begin
        get_name
        check_total_points_count
        check_points_consistency
        get_coordinates
      rescue AirfoilChecker::ErrorPointsCount => e
        errors << e
        return false
      rescue ErrorPointsConsistency => e
        errors << e
        return false
      end

      begin
        tries += 1
        if tries > 10
          return false
        end
        check_increase_decrease
        check_x_range
        get_top_bottom
        check_points_count
        check_closure
        check_base_line
      rescue AirfoilChecker::ErrorXRange => e
        fix_x_range
        corrections << 'fix_x_range'
        #errors << e
        retry
      rescue AirfoilChecker::ErrorClosure => e
        fix_closure
        corrections << 'fix_closure'
        retry
      rescue AirfoilChecker::ErrorSameTopXCoordinate => e
        fix_top_same_points
        corrections << 'fix_top_same_points'
        retry
      rescue AirfoilChecker::ErrorSameBottomXCoordinate => e
        fix_bottom_same_points
        corrections << 'fix_bottom_same_points'
        retry
      rescue AirfoilChecker::ErrorIncreaseDecrease => e
        errors << e
        return false
      rescue AirfoilChecker::ErrorBaseLine => e
        fix_base_line
        corrections << 'fix_base_line'
        fix_x_range
        corrections << 'fix_x_range'
      end
      @data_correct = true
      return true
    end

  end

end

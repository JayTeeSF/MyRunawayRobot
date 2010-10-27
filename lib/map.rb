require './lib/nil_extensions.rb'

# for testing:
#require 'rubygems'
#require 'ruby-debug'
class Map
  attr_accessor :height, :width, :matrix, :robot, :map_folds

  ANSI_RED      ="\033[0;31m"
  ANSI_LRED      ="\033[1;31m"
  ANSI_GRAY     = "\033[1;30m"
  ANSI_LGRAY    = "\033[0;37m"
  ANSI_BLUE     = "\033[0;34m"
  ANSI_LBLUE    = "\033[1;34m"

  ANSI_RESET      = "\033[0m"
  ANSI_REVERSE    = "\033[7m"

  ANSI_BACKBLACK  = "\033[40m"
  ANSI_BACKRED    = "\033[41m"

  def initialize(options={})
    @debug = options[:debug]
    options.delete(:debug)
    #puts "options: #{options.inspect}"
    @map_folds = {}
  end

  #
  # NOTE: since these aren't optional, I shouldn't use an options hash
  # TODO: replace hash w/ argument params
  # required 'options':
  # :terrain_string, :board_x, :board_y
  #
  def config(options={})
    @terrain = options[:terrain_string]
    @width = options[:board_x] - 1
    @height = options[:board_y] - 1
    @row_success = @height + 1
    @col_success = @width + 1

    # construct_matrix
  end

  def clear_matrix
    @matrix = []
  end

  def self.robot
    'R'
  end

  def map_dup(_matrix=@matrix)
    Marshal.load(Marshal.dump(_matrix))
  end

  # human readable
  def draw_matrix(_matrix=@matrix, row=nil,col=nil)
    # return unless @debug
    if _matrix.empty?
      construct_matrix
      _matrix = @matrix
    end
    if (row && col)
      # deep copy the array, before inserting our robot
      _this_matrix = map_dup
      # puts "_this_m: #{_this_matrix.inspect}"
      _this_matrix[row] ||= []
      _this_matrix[row][col] = (_this_matrix[row][col] == Map.safe()) ? Map.robot() : Map.boom
      # puts "_this_m: #{_this_matrix.inspect}"
    else
      _this_matrix = _matrix
    end

    puts "\n#-->"
    _this_matrix.each_with_index do |current_row,i|
      current_row.each_with_index do |e,j|
        current_distance = i + j
        if "R" == e
          current_row[j] =   "#{ANSI_RED}R#{ANSI_RESET}"
          next
        end

        if current_distance < robot.min
          current_row[j] = (e == 1)  ?  '+' : "#{ANSI_LBLUE}.#{ANSI_RESET}"
        elsif (current_distance % robot.max) == 0 && (current_distance % robot.min) == 0
          current_row[j] = (e == 1)  ?  "#{ANSI_REVERSE}^#{ANSI_RESET}" : "#{ANSI_REVERSE}#{ANSI_LBLUE}`#{ANSI_RESET}"
        elsif (current_distance % robot.min) == 0
          current_row[j] = (e == 1)  ?  "#{ANSI_REVERSE}>#{ANSI_RESET}" : "#{ANSI_REVERSE}#{ANSI_LBLUE}`#{ANSI_RESET}"
        elsif current_distance > robot.min && current_distance < robot.max
          current_row[j] = (e == 1)  ?  '/' : "#{ANSI_BLUE}`#{ANSI_RESET}"
        elsif (current_distance % robot.max) == 0
          current_row[j] = (e == 1)  ?  "#{ANSI_REVERSE}<#{ANSI_RESET}" : "#{ANSI_REVERSE}#{ANSI_BLUE}`#{ANSI_RESET}"
        else
          current_row[j] = (e == 1)  ?  "+" : "#{ANSI_LGRAY}.#{ANSI_RESET}"
        end
      end
      puts "#{current_row * ' '}"
    end
    puts "#<--\n"

  # rescue Exception => e
  #   puts "Unable to display this matrix: #{e.message}"
  end

  def construct_matrix
    clear_matrix
    puts "constructing matrix..."
    next_cell = cell_generator
    row_bomb = {-1 => 0}

    (0).upto(@height) do |y_val|
      final_row_bomb = nil
      prev_row_bomb = row_bomb[y_val -1] ||= @col_success
      matrix_row = []
      (0).upto(@width) do |x_val|
        ascii_char = next_cell.call
        if final_row_bomb
          ascii_char = Map.bomb
        else
          if x_val >= (prev_row_bomb - 1) && Map.bomb == ascii_char
            row_bomb[y_val] = final_row_bomb = x_val
          end
        end

        matrix_row << ascii_char
      end # end-width

      @matrix << matrix_row
    end # end height

    # determine if a column has a "final" bomb...
    col_bomb = {-1 => 0}
    (0).upto(@width) do |x_val|
      final_col_bomb = nil
      prev_col_bomb = col_bomb[x_val -1] ||= @row_success
      (0).upto(@height) do |y_val|
        ascii_char = @matrix[y_val][x_val]
        if final_col_bomb
          # puts "COL: xxx"
          @matrix[y_val][x_val] = Map.bomb
        else
          if y_val >= (prev_col_bomb - 1) && Map.bomb == ascii_char
            col_bomb[x_val] = final_col_bomb = y_val
          end
        end # if we've got a final...bmb

      end # end height-loop
    end # end width-loop

    fill_in_dead_ends
  end
    
  # 
  # perhaps we can fold the map, so we only have to verify one-segment of path
  # update one quadrant w/ the constraints of all others
  # call this from Robot's init method, for the (min-) start-pts...
  # 
  def fold_map(r,c)
    puts "folding..." # perhaps only once
    @map_folds["#{r}_#{c}"] ||= begin
      # perhaps we ought to shrink the folded matricies...
      tmp_matrix = []; r.times {|i| tmp_matrix[i] = [] }

      # ...start at c+c, r+r...
      # start at c,r, because we've already tested upto that point...
      (c+c).upto(@width) do |x_val|
        (r+r).upto(@height) do |y_val|
          current_distance = x_val + y_val
          # # can't reach these...
          # next if r > y_val
          # next if c > x_val
          
          row = (y_val - 2 * r) # where are we relative to start
          col = (x_val - 2 * c) # where are we relative to start
          row = 0 == r ? 0 : row % ( r )
          col = 0 == c ? 0 : col % ( c )
          puts "min: #{robot.min} vs. current_d: #{current_distance}; r: #{r}; c: #{c};  y_val: #{y_val}, x_val: #{x_val}"
          puts "row: #{row}/col: #{col}"

          if Map.bomb == matrix[y_val][x_val] && row >= 0 && row <= @height && col >= 0 && col <= @width
            tmp_matrix[row] ||= []
            tmp_matrix[row][col] = Map.bomb
            puts "new bomb"
          end
        end
      end
      tmp_matrix
    end
  end

  # fill-in dead-ends in the matrix w/ bombs
  def fill_in_dead_ends direction=:both

    if :both == direction || :reverse == direction #reverse
      (0).upto(@height) do |y_val|
        (0).upto(@width) do |x_val|
          next if y_val == 0 || x_val == 0 || fail?(y_val, x_val)

          if fail?( *Map.reverse_move(Robot.down, y_val,x_val) ) && fail?( *Map.reverse_move(Robot.right, y_val,x_val) )
            # puts "filling-in a dead-end"
            @matrix[y_val][x_val] = Map.bomb
          end
        end
      end
    end

    if :both == direction || :forward == direction# forward
      @height.downto(0) do |y_val|
        @width.downto(0) do |x_val|
          next if y_val == @height || x_val == @width || fail?(y_val, x_val)

          if fail?( *Map.move(Robot.down, y_val,x_val) ) && fail?( *Map.move(Robot.right, y_val,x_val) )
            # puts "filling-in a dead-end"
            @matrix[y_val][x_val] = Map.bomb
          end
        end
      end
    end

  end

  #
  # return a terrain iterator
  # default: char-by-char
  # :terrain_string=>"..X...X.."
  #
  def cell_generator
    terrain_ary = @terrain.split(//)
    increment = 1
    i = -1

    # using #'s instead of chars provides a decent speed-up:
    # actually took 7.633317 seconds vs. 8.838757 ...
    lambda { i += increment; terrain_ary[i].sub(/X/,"1").sub(/\./,"0").to_i }
  end

  def success?(row,col)
    row > @height || col > @width
  end

  def fail?(row,col, _matrix=@matrix)
    1 == _matrix[row][col] # Map.bomb; have nil_extensions handle out-of-bound issues
  end

  def self.reverse_move(direction, row, col, amount_down=1, amount_right=1)
    basic_move direction, row, col, -1, -1
  end

  def self.basic_move(direction, row, col, amount_down=1, amount_right=1)
    (direction == Robot.down) ? row += amount_down : col += amount_right
    [row,col]
  end

  def self.move(direction, row, col)
    (direction == Robot.down) ? row += 1 : col += 1
    [row,col]
  end

  def avail?(row,col, _matrix=@matrix)
    ! fail?(row, col, _matrix)
  end
  
  # def num_down_til_right(row, col)
  #   count = 0
  #   begin 
  #     row += 1
  #     count += 1
  #     unless avail?(row,col)
  #       count = 0
  #       break
  #     end
  #   end until avail?(row, col + 1)
  #   count
  # end
  # 
  # def num_right_til_down(row, col)
  #   count = 0
  #   begin 
  #     col += 1
  #     count += 1
  #     unless avail?(row,col)
  #       count = 0
  #       break
  #     end
  #   end until avail?(row + 1, col)
  #   count
  # end
  # 
  # def num_right_from_start
  #   @nrtd ||= num_right_til_down(0,0)
  # end
  # 
  # def num_down_from_start
  #   @ndtr ||= num_down_til_right(0,0)
  # end

  def first_bomb_down
    @fbd ||= down_til_bomb(0,0)
  end
  def first_bomb_right
    @fbr ||= right_til_bomb(0,0)
  end
  
  def down_til_bomb(row, col)
    count = 0
    begin 
      row += 1
      count += 1
    end until fail?(row, col)
    count
  end  
  
  def right_til_bomb(row, col)
    count = 0
    begin 
      col += 1
      count += 1
    end until fail?(row, col)
    count
  end  
  
  def satisfy?(path_ary=[], row=0, col=0)
    path_ary.each do |direction|
      row, col = Map.move(direction, row, col)
      return false if fail?(row,col)
    end # end-each
    return true
  end

  #  def non_recursive_verify(path_ary=[], row=0, col=0)
  def verify(path_ary=[], row=0, col=0)
    #puts "verifying..."
    # draw = ! @map_folds["#{row}_#{col}"]
    # _matrix = fold_map(path_ary.count(Robot.down),path_ary.count(Robot.right))
    # draw_matrix(_matrix,row,col) if draw
    _matrix = @map_folds["#{row}_#{col}"] || fold_map(path_ary.count(Robot.down),path_ary.count(Robot.right))
      # @matrix
    
    #while true # begin
      if success?(row,col) # faster to do this single check than multiple checks
        return true
      end
      
      path_ary.each do |direction|
        row, col = Map.move(direction, row, col)
        return false if fail?(row,col, _matrix)
      end # end-each
      
      # if we made it through the folded matrix --even once, then we're good!
      return success?(row,col) || avail?(row, col, _matrix)
    #end # while true
  end

  #   def recursive_verify(path_ary=[], row=0, col=0)
  #     path_ary.each do |direction|
  #       row, col = Map.move(direction, row, col)
  #       return false if fail?(row,col)
  #     end # end-each
  #     return true if success?(row,col) # faster to do this single check than multiple checks
  #     verify(path_ary, row, col)
  #   end

  def self.success
    'S' #made it to the border (assuming we expand the matrix...)
  end

  def self.boom
    'B' #the robot exploded
  end

  def self.bomb
    1
  end

  def self.safe
    0
  end

end

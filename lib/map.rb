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
    # @row_success = @height + 1
    #@col_success = @width + 1

    # construct_matrix
  end

  def fill_matrix
    @matrix = construct_matrix
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
  def draw_matrix(_matrix=nil, row=nil,col=nil)
    # return unless @debug
    if _matrix.nil?
      puts "nil matrix"
      clear_matrix
      _matrix = fill_matrix
    elsif _matrix.empty? # someone else's matrix ?!
      puts "empty matrix"
      _matrix = construct_matrix( _matrix )
    end
    # puts "drawing: _matrix: #{_matrix.inspect}"
    
    if (row && col)
      # deep copy the array, before inserting our robot
      _this_matrix = map_dup(_matrix)
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
        
        if Map.boom() == e
          current_row[j] =   "#{ANSI_RED}B#{ANSI_RESET}"
          next
        end
        
        if Map.robot() == e
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

  def construct_matrix(_matrix=@matrix, next_cell=cell_generator, _height=@height, _width=@width)
    puts "constructing matrix..."
    row_bomb = {-1 => 0}

    (0).upto(_height) do |y_val|
      final_row_bomb = nil
      prev_row_bomb = row_bomb[y_val -1] ||= _width + 1
      matrix_row = []
      (0).upto(_width) do |x_val|
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

      _matrix << matrix_row
    end # end height

    # determine if a column has a "final" bomb...
    col_bomb = {-1 => 0}
    (0).upto(_width) do |x_val|
      final_col_bomb = nil
      prev_col_bomb = col_bomb[x_val -1] ||= _height + 1
      (0).upto(_height) do |y_val|
        ascii_char = _matrix[y_val][x_val]
        if final_col_bomb
          # puts "COL: xxx"
          _matrix[y_val][x_val] = Map.bomb
        else
          if y_val >= (prev_col_bomb - 1) && Map.bomb == ascii_char
            col_bomb[x_val] = final_col_bomb = y_val
          end
        end # if we've got a final...bmb

      end # end height-loop
    end # end width-loop

    _matrix = fill_in_dead_ends( _matrix )

    _matrix
  end
  
  def coord_generator(r,c)
    lambda {r += r; c += c; [r,c]}
  end
  
  # 
  # perhaps we can fold the map, so we only have to verify one-segment of path
  # update one quadrant w/ the constraints of all others
  # call this from Robot's init method, for the (min-) start-pts...
  # 
  def fold_map(r,c)
    # puts "folding..."
    @map_folds["#{r}_#{c}"] ||= begin

      next_coord = coord_generator(r,c)
      # init:
      tmp_matrix = []
      (0).upto(c) do |c_val|
        (0).upto(r) do |r_val|
          tmp_matrix[r_val] ||= []
          tmp_matrix[r_val][c_val] = Map.safe
        end
      end
      # puts "\ninit-matrix: #{tmp_matrix.inspect}"

      # keep generating next-coord
      # then loop over tmp_matrix, and fill-in any bombs from big-matrix
      # that exist at tmp_r + current_coord and tmp_c + current_coord
      current_coord = [r,c]
      begin
        (0).upto(tmp_matrix.first.size - 1) do |c_val| # width
          (0).upto(tmp_matrix.size - 1) do |r_val| # height

            if Map.bomb == matrix[r_val + current_coord.first][c_val + current_coord.last]
              tmp_matrix[r_val][c_val] = Map.bomb
            end

          end # end-height
        end # end-width
        current_coord = next_coord.call
      end until success?(*current_coord)

      # puts "matrix: #{tmp_matrix.inspect}"
      # TODO: wrap tmp_matrix inside a cell_generator, and call construct_matrix!!!
      # tmp_matrix
      construct_matrix( tmp_matrix, cell_generator( matrix_to_ary( tmp_matrix ) ), tmp_matrix.size - 1, tmp_matrix.first.size - 1 )
    end
  end

  # fill-in dead-ends in the matrix w/ bombs
  def fill_in_dead_ends _matrix=@matrix, direction=:both

    if :both == direction || :reverse == direction #reverse
      (0).upto(@height) do |y_val|
        (0).upto(@width) do |x_val|
          next if y_val == 0 || x_val == 0 || fail?(y_val, x_val)

          if fail?( *Map.reverse_move(Robot.down, y_val,x_val) ) && fail?( *Map.reverse_move(Robot.right, y_val,x_val) )
            # puts "filling-in a dead-end"
            _matrix[y_val][x_val] = Map.bomb
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
            _matrix[y_val][x_val] = Map.bomb
          end
        end
      end
    end

    _matrix
  end

  def matrix_to_ary( _matrix=@matrix )
    [].tap do |ary|
      _matrix.each do |row|
        row.each do |element|
          ary << element
        end # col
      end # row
    end # tap
  end

  #
  # return a terrain iterator
  # default: char-by-char
  # :terrain_string=>"..X...X.."
  #
  def cell_generator( terrain_ary=@terrain.gsub(/X/,"1").gsub(/\./,"0").split(//) )
    increment = 1
    i = -1

    # using #'s instead of chars provides a decent speed-up:
    # actually took 7.633317 seconds vs. 8.838757 ...
    # lambda { i += increment; terrain_ary[i].sub(/X/,"1").sub(/\./,"0").to_i }
    lambda { i += increment; terrain_ary[i].to_i }
  end

  def success?(row,col,height=@height,width=@width)
    row > height || col > width
  end

  def fail?(row,col, _matrix=@matrix)
    Map.bomb == _matrix[row][col] #1; have nil_extensions handle out-of-bound issues
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

  # def first_bomb_down
  #   @fbd ||= down_til_bomb(0,0)
  # end
  # def first_bomb_right
  #   @fbr ||= right_til_bomb(0,0)
  # end
  # 
  # def down_til_bomb(row, col)
  #   count = 0
  #   begin 
  #     row += 1
  #     count += 1
  #   end until fail?(row, col)
  #   count
  # end  
  # 
  # def right_til_bomb(row, col)
  #   count = 0
  #   begin 
  #     col += 1
  #     count += 1
  #   end until fail?(row, col)
  #   count
  # end  
  # 
  # def satisfy?(path_ary=[], row=0, col=0)
  #   path_ary.each do |direction|
  #     row, col = Map.move(direction, row, col)
  #     return false if fail?(row,col)
  #   end # end-each
  #   return true
  # end
  # 
  # def full_verify(path_ary=[], row=0, col=0)
  #   puts "good-chance of a winner: #{path_ary.inspect}; from 0,0"
  #   while true # begin
  #     path_ary.each do |direction|
  #       row, col = Map.move(direction, row, col)
  #       if fail?(row,col)
  #         puts "hit a bomb in third/n-th pass-through"
  #         return false
  #       end
  #     end # end-each
  #     
  #     if success?(row,col) # faster to do this single check than multiple checks
  #       puts "made it!!!"
  #       return true
  #     end
  #   end
  # end
  
  #  def non_recursive_verify(path_ary=[], row=0, col=0)
  def verify(path_ary=[], row=0, col=0)
    # puts "#{row}(#{path_ary.count(Robot.down)}) /#{col}(#{path_ary.count(Robot.right)})"
    # row = path_ary.count(Robot.down)
    # col = path_ary.count(Robot.right)
    start_row, start_col = [row, col]

    # puts "verifying..."
    draw = ! @map_folds["#{row}_#{col}"]
    _matrix = fold_map(row,col)
      
      # draw_matrix(_matrix, row, col) if draw
      row, col = [0,0]
      draw_matrix(_matrix, row, col) if draw

    # unless _matrix.flatten.count(0) > 0
    #   # puts "QUICK BOMB"
    #   return false
    # end
    
    # 
    # #while true # begin
    # if fail?(row,col, _matrix)
    #   # puts "hit an immediate bomb!"
    #   return false
    # end
    # 
    #   if success?(row,col) # faster to do this single check than multiple checks
    #     puts "ending before we start!"
    #     return true
    #   end
    #   
    2.times { # after folding this should be max!
      path_ary.each do |direction|
        if fail?(row,col, _matrix)
          # puts "hit a bomb at start of first/second pass-through"
          return false
        end
        
        row, col = Map.move(direction, row, col)
        # if fail?(row,col, _matrix)
        #   # puts "hit a bomb in first/second pass-through"
        #   return false
        # end
      end # end-each
      
      #if success?(row,col, _matrix.first.size, _matrix.size) # faster to do this single check than multiple checks
      #  return true
      #end
      
    }
    
    #   
    #   # if we made it through the folded matrix --even once, then we're good!

      # if fail?(row,col, _matrix)
      #   # puts "hit a bomb at start of first/second pass-through"
      #   return false
      # end
      
      puts "recursive-verify!"
      return recursive_verify(path_ary, start_row, start_col)
      #return recursive_verify(path_ary, row, col)
    #end # while true
  end

  def recursive_verify(path_ary=[], row=0, col=0)
    return true if success?(row,col) # faster to do this single check than multiple checks
    path_ary.each do |direction|
      row, col = Map.move(direction, row, col)
      return false if fail?(row,col)
    end # end-each
    # return true if success?(row,col) # faster to do this single check than multiple checks
    recursive_verify(path_ary, row, col)
  end

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

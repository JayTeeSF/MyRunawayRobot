require './lib/nil_extensions.rb'
class Map
  attr_accessor :height, :width 

  def initialize(options={})
    @debug = options[:debug]
    options.delete(:debug)
    #puts "options: #{options.inspect}"
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
    
    clear_matrix
    construct_matrix
  end

  def clear_matrix
    @matrix = []
  end

  def self.robot
    'R'
  end

  # human readable
  def draw_matrix(row=nil,col=nil)
    # return unless @debug
    construct_matrix if @matrix.empty?
    if (row && col)
      # deep copy the array, before inserting our robot
      matrix = Marshal.load(Marshal.dump(@matrix))
      matrix[row][col] = (matrix[row][col] == Map.safe()) ? Map.robot() : Map.boom
    else
      matrix = @matrix
    end

    puts "\n#-->"
    matrix.each do |current_row|
      current_row.map!{|i| (i == 1) ? 'T' : '`' }
      puts "#{current_row * ' '}"
    end
    puts "#<--\n"

  rescue Exception => e
    puts "Unable to display this matrix: #{e.message}"
  end

  def construct_matrix
    return unless @matrix.empty?
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

  def fail?(row,col)
    @matrix[row][col] == Map.bomb
#  rescue Exception => e
#      return false # we exceeded a bound
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

  def avail?(row,col)
    # @matrix[row][col] != Map.bomb
    ! fail?(row, col)
  end
  
#  def non_recursive_verify(path_ary=[], row=0, col=0)
  def verify(path_ary=[], row=0, col=0)
#puts "verifying..."
    while true # begin
      path_ary.each do |direction|
        row, col = Map.move(direction, row, col)
        return false if fail?(row,col)
      end # end-each
      return true if success?(row,col) # faster to do this single check than multiple checks
    end # while true
  end

# #  alias :verify :non_recursive_verify
# #
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

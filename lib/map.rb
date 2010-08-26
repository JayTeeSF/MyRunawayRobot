require './lib/binary_tree.rb'

class Map
  
  MAX_Y = 2
  # BAD_CYCLE_LEN = 5
  @@solutions = './solutions.txt'
  attr_accessor :height, :width, :terrain, :matrix, :debug, :max_cycle, :bomb_tree
  #, :known_bad_cycles, :use_known_bad, :store_bad, :check_bad, :bad_cycle_len

  def initialize(options={})
    @debug = options[:debug]
    # @known_solutions = (options[:cache_off].nil?) ? load : Hash.new{|h, k| h[k]=Hash.new(&h.default_proc) }
    # options.delete(:cache_off)
    options.delete(:debug)
    #puts "options: #{options.inspect}"

    # must call config from elsewhere!
    # config(options) if options && options != {}
  end
  
  #
  # NOTE: since these aren't optional, I shouldn't use an options hash
  # TODO: replace hash w/ argument params
  # required 'options':
  # :terrain_string, :board_x, :board_y
  #
  def config(options={})
    @terrain = options[:terrain_string]
    @num_wide = options[:board_x]
    @width = @num_wide - 1
    @height = options[:board_y] - 1
    @max_cycle = options[:ins_max]
    # @safe_arys = []
    @bomb_tree = BinaryTree.new
    @max_y = nil
    #@known_bad_cycles = []
    #bad_cycle_len = nil

    # apparently this feature slows us down!!!
    #@store_bad = false
    #@use_known_bad = options[:use_known_bad] || false
    #@check_bad = @use_known_bad

    clear_matrix
    #puts "map-config constructing matrix"
    construct_matrix
    clear_matrix
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
    matrix.each {|current_row| puts "#{current_row * ' '}"}
    puts "#<--\n"

  rescue Exception => e
    puts "Unable to display this matrix: #{e.message}"
  end

  def construct_matrix
    return unless @matrix.empty?
    next_cell = cell_generator
    row_bomb = {-1 => 0}

    (0..@height).each do |y_val|
      final_row_bomb = nil
      prev_row_bomb = row_bomb[y_val -1] ||= @width + 1
      matrix_row = []
      (0 .. @width).each do |x_val|
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

      # final_char =  << final_row_bomb ? Map.bomb : Map.success
      # # append enough to ensure any repeated-cycle ends on a square that can be checked # nonsense!
      # max_cycle.times { matrix_row << final_char }

      @matrix << matrix_row
    end # end height

    # determine if a column has a "final" bomb...
    col_bomb = {-1 => 0}
    (0 .. @width).each do |x_val|
      final_col_bomb = nil
      prev_col_bomb = col_bomb[x_val -1] ||= @height + 1
      (0 .. @height).each do |y_val|
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

    fill_in_dead_ends false
    fill_in_dead_ends true
    fill_bombs
    
    #returns = []
    #@width.times{ returns << "\n" }
    #puts "constructed:\n#{@matrix.zip(returns)}"

    # draw_matrix
    puts @bomb_tree
  end
  
  # not strings: row_col
  # but a hash:
  # row * @width + col to reference each cell uniquely!
  
  # def max_y
  #   @max_y ||= begin
  #     MAX_Y / @width
  #     # result = 60 / @width # 200 => 579(ish) sec; 400 => 878.797 sec;
  #     # 128 => ?
  #     # 100 => 389.026;
  #     # 64 => ?
  #     # 60 => 374.379;
  #     # 32 => 382.785
  #     # 16 => ?
  #     # 10 => 384.86
  #     # 8 => 383.056
  #     # 7 => ?
  #     # 2 => 370.985
  #     # 1 => ?
  #     # puts "max_y: #{result}"
  #     # result
  #   end
  # end

  def fill_bombs
    bombs = []
    # @safe_arys = []
    # i = -1 # we'll increment to 0
    (0..@height).each do |y_val|
      # if ((0 == max_y) || (0 == (y_val % max_y))) # @safe_arys[i].length > 380
      #   i += 1
      #   @safe_arys[i] = []
      # end      
      (0..@width).each do |x_val|
        # @bombs[i] << "#{y_val}_#{x_val}" if safe(y_val, x_val)
        if fail(y_val, x_val)
          bombs << tree_val(y_val, x_val)
        end
      end
    end
    
    bombs.shuffle.each do |bomb|
      @bomb_tree.add(bomb)
    end
  end
  
  def tree_val row, col
    (row * @num_wide) + col + 1
  end
  
  # def bombs_include?(str, row)
  def bombs_include?(row, col)
    # # @bombs.each do |safe_ary|
    # i = (0 == max_y) ? row : row.div(max_y)
    # # puts "i: #{i}: => #{bombs[i].inspect}"
    # return false if i > (@bombs.size - 1)
    # return true if @bombs[i].include?(str)
    # # end
    # return false
    return @bomb_tree.find(tree_val(row, col))
  end

  # 
  # def fill_bomb_ary
  #   @bomb_ary = []
  #   (0..@height).each do |y_val|
  #     (0..@width).each do |x_val|
  #       @bomb_ary << "#{y_val}_#{x_val}" if fail(y_val, x_val)
  #     end
  #   end
  # end

  # fill-in dead-ends in the matrix w/ bombs
  def fill_in_dead_ends reverse=false
    if reverse
      (0..@height).each do |y_val|
        (0..@width).each do |x_val|
          next if y_val == 0 || x_val == 0 || fail(y_val, x_val)

          if fail( *Map.reverse_move(Robot.down, y_val,x_val) ) && fail( *Map.reverse_move(Robot.right, y_val,x_val) )
            @matrix[y_val][x_val] = Map.bomb
          end

        end
      end
    else
      (0..@height).reverse_each do |y_val|
        (0..@width).reverse_each do |x_val|
          next if y_val == @height || x_val == @width || fail(y_val, x_val)

          if fail( *Map.move(Robot.down, y_val,x_val) ) && fail( *Map.move(Robot.right, y_val,x_val) )
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
    lambda { i += increment; terrain_ary[i] }
  end

  def immediate_success(row,col)
    1 + @height == row || 1 + @width == col
  end

  def success(row,col)
    row > @height || col > @width
  end

  # 
  # def done(row,col)
  #   return 1 if row > @height || col > @width # @matrix[row][col] == Map.success || 
  #   #success(row,col) 
  #   return 0 if @matrix[row][col] == Map.bomb
  #   #fail(row,col) 
  #   return -1
  # end

  def fail(row,col)
    @matrix[row][col] == Map.bomb
  end
  
  def safe(row,col)
    @matrix[row][col] == Map.safe
  end

  def self.reverse_move(direction, row, col, amount_down=1, amount_right=1)
    (direction == Robot.down) ? row -= amount_down : col -= amount_right
    [row,col]
  end

  def self.move(direction, row, col, amount_down=1, amount_right=1)
    (direction == Robot.down) ? row += amount_down : col += amount_right
    [row,col]
  end

  def avail?(row,col)
    # immediate_success(row,col) || @matrix[row][col] == Map.safe
    immediate_success(row,col) || !bombs_include?(row, col)
  end

#   def repeat_verify(num_down, num_right,path_ary)
#     row = num_down
#     col = num_right
#   
#   # get us to the _end_ of the board (or fail)
#     begin
#       return false if fail(row, col)
#       row += num_down
#       col += num_right
#     end while !success(row,col)
#     
#     # now run through the path in reverse... until we reach the starting-pt (num_down,num_right) (or fail)
#     reverse_verify(path_ary,row,col, num_down, num_right )
#   end
# 
#   def reverse_verify(path_ary, row, col, start_row=0, start_col=0)
#     reversed_path = path_ary.reverse
# # puts "following rp#{reversed_path} to get from: r#{row}/c#{col} back-to: sr#{start_row}/sc#{start_col}"
#     
#     begin
#     # while true
#       reversed_path.each do |direction|
#         row, col = *Map.reverse_move(direction, row, col)
# # puts "now at: r#{row}/c#{col}"
#         next if success(row,col) # winning, requires getting back to a spot ON the board
#         return false if fail(row,col)
#         return true if row == start_row && col == start_col
#       end # end-each
# # rescue Exception => e
# #   puts "r#{row}/c#{col}; e: #{e.message}"
# #   draw_matrix
# #   puts "drew it"
# #   raise e
#   
#   end until row <= start_row && col <= start_col
# 
#     return true
#   end


  #
  # return a string of robot directions
  #
  
  def debug_verify(path_ary=[], row=0, col=0)
    puts "verifying path (from: r#{row}/c#{col}): #{path_ary.inspect}..."
    while ! success(row, col)
      path_ary.each do |direction|
        row, col = *Map.move(direction, row, col)
        # draw_matrix(row, col)
  puts "moved-to: r#{row}/c#{col}"
        if bombs_include?(row, col)
  puts "found bomb..."
  unless success(row, col)
          return false
        end
        end
      end # end-each
    end
    puts "dropping through..."
    return true
  end

  # def debug_verify(path_ary=[], row=0, col=0)
  #   puts "verifying path (from: r#{row}/c#{col}): #{path_ary.inspect}..."
  #   path_down, path_across = *[row, col]
  #   while true # begin
  #     path_ary.each do |direction|
  #       row, col = *Map.move(direction, row, col)
  #       draw_matrix(row,col)
  #       return true if immediate_success(row,col)
  #       return false if fail(row,col)
  #     end # end-each
  #     return bulk_verify(path_down, path_across, path_ary)
  #     # not sure why, but this early-return is WORKING; and FAST
  #     # return true
  #     # return repeat_verify(path_down, path_across, row, col)
  #   end # while true
  # 
  #   puts "dropping through..."
  #   return true
  # end

  # def verify(path_ary=[], row=0, col=0)
  #   path_down, path_across = *[row, col]
  #   while true # begin
  #     path_ary.each do |direction|
  #       row, col = *Map.move(direction, row, col)
  #       return true if immediate_success(row,col)
  #       return false if fail(row,col)
  #     end # end-each
  #     return bulk_verify(path_down, path_across, path_ary)
  #     # not sure why, but this early-return is WORKING; and FAST
  #     # return true
  #     # return repeat_verify(path_down, path_across, row, col)
  #   end # while true
  #   
  #   
  #   return true
  # end

  def verify(path_ary=[], row=0, col=0)
    # path_down, path_across = *[row, col]
    while ! success(row, col)
      path_ary.each do |direction|
        row, col = *Map.move(direction, row, col)
        if bombs_include?(row, col)
          return false unless success(row, col)
        end
      end # end-each
    end
    return true
  end

  def self.success
    'S' #made it to the border (assuming we expand the matrix...)
  end

  def self.boom
    'B' #the robot exploded
  end

  def self.bomb
    'X'
  end

  def self.safe
    '.'
  end

  # def self.value_of ascii_char
  #   case ascii
  #   when self.bomb #'X'
  #     -1
  #   when self.safe # '.'
  #     0
  #   when self.success # 'S'
  #     1
  #   end
  # end

  # #
  # # Check to see if we've already solved this map (i.e. regardless of the
  # # 'level')
  # #
  # def lookup_solution(min,max)
  #   ret_val = @known_solutions[@terrain][@height][@width][min][max]
  #   ret_val.kind_of?('Array') ? ret_val : nil 
  # end

  #def known_bad?(path_ary=nil)
  #  return true unless path_ary
  #  @known_bad_cycles.each do |cycle|
  #    max_idx = cycle.size - 1
  #    if path_ary[0..max_idx] == cycle
  #      puts "found bad cycle (#{cycle}) in #{path_ary}..." if @debug
  #      return true
  #    end
  #  end
  #  #puts "didn't find bad cycle...[#{@known_bad_cycles.inspect} vs.  #{path_ary.inspect}]"
  #  return false
  #end

  # # 
  # # restore known solutions, from file
  # # TODO: actually use JSON (require 'JSON', etc...)
  # # 
  # def load(solutions=@@solutions)
  #   puts "returning hash of known solutions..." if @debug
  #   known_solutions = Hash.new{|h, k| h[k]=Hash.new(&h.default_proc) }
  #   if File.exists?(solutions)
  #     handle = File.open(solutions, 'r')
  #     while line = handle.gets
  #       puts "matching line: #{line}" if @debug
  #       m = /terrain \=\> ([^,]+), height \=\> (\d+), width \=\> (\d+), min \=\> (\d+), max \=\> (\d+), path \=\> (\w+)\s*$/.match(line)
  #       puts "m(#{m.class.to_s}): #{m.inspect}" if @debug
  #       known_solutions[m[0]][m[1]][m[2]][m[3]][m[4]] = m[5].split(//)
  #     end
  #   end
  #   known_solutions
  # end
  # 
  # #
  # # append a known solution to our solutions-file
  # # TODO: actually use JSON (require 'JSON', etc...)
  # #
  # def save(min, max, path_str, solutions=@@solutions)
  #   return false if lookup_solution(min,max)
  #   entry_str = "terrain => #{@terrain}," +
  #   " height => #{@height}, width => #{@width}," +
  #   " min => #{min}, max => #{max}," +
  #   " path => " + path_str
  # 
  #   File.open(solutions, "a") do |solutions_file|
  #     solutions_file.puts entry_str
  #   end
  #   return true
  # end

end

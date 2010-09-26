require './lib/nil_extensions.rb'
class Map
  # BAD_CYCLE_LEN = 5
  @@solutions = './solutions.txt'
  attr_accessor :height, :width, :terrain, :matrix, :debug, :max_cycle
  #, :exit_r_and_d_counts
  #, :known_bad_cycles, :use_known_bad, :store_bad, :check_bad, :bad_cycle_len

  def initialize(options={})
    @debug = options[:debug]
    # @known_solutions = (options[:cache_off].nil?) ? load : Hash.new{|h, k| h[k]=Hash.new(&h.default_proc) }
    # options.delete(:cache_off)
    options.delete(:debug)
    #puts "options: #{options.inspect}"

    # must call config from elsewhere!
    # config(options) if options && options != {}
    # @exit_r_and_d_counts = [] # e.g. [[5,7], [6,7], etc...]
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
    @max_cycle = options[:ins_max]
    
    # @bomb_hash = {}
    #@known_bad_cycles = []
    #bad_cycle_len = nil

    # apparently this feature slows us down!!!
    #@store_bad = false
    #@use_known_bad = options[:use_known_bad] || false
    #@check_bad = @use_known_bad

    clear_matrix
    #puts "map-config constructing matrix"
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

#puts "mr#{row}:" + matrix[row]
      #tmp = matrix[row].split(//)
      #tmp[col] = (safe?(row,col)) ? Map.robot() : Map.boom
      #matrix[row] = tmp.join
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
    puts "constructing matrix..."
    next_cell = cell_generator
    row_bomb = {-1 => 0}

    (0..@height).each do |y_val|
      final_row_bomb = nil
      prev_row_bomb = row_bomb[y_val -1] ||= @col_success
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
        
        # if ascii_char == Map.bomb
        #   @bomb_hash["#{y_val}_#{x_val}"] = Map.bomb
        # end

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
      prev_col_bomb = col_bomb[x_val -1] ||= @row_success
      (0 .. @height).each do |y_val|
        ascii_char = @matrix[y_val][x_val]
        if final_col_bomb
          # puts "COL: xxx"
          @matrix[y_val][x_val] = Map.bomb
          
          # @bomb_hash["#{y_val}_#{x_val}"] = Map.bomb
          
        else

          if y_val >= (prev_col_bomb - 1) && Map.bomb == ascii_char
            col_bomb[x_val] = final_col_bomb = y_val
          end
        end # if we've got a final...bmb

      end # end height-loop
    end # end width-loop

    fill_in_dead_ends true
    fill_in_dead_ends false

    # exit_r_and_d_counts
    
    #returns = []
    #@width.times{ returns << "\n" }
    #puts "constructed:\n#{@matrix.zip(returns)}"
    #draw_matrix
    #@matrix = stringify_rows(@matrix) #<-- takes way too long to decode
    # puts "matrix[0].class = #{@matrix[0].class}"
  end

  # TODO: DRY me up
  def exit_r_and_d_counts
    col = @width + 1
    (0..@height).each do |row|
      @exit_r_and_d_counts << [row, col] if avail?(row,@width)
    end
    
    row = @height + 1
    (0..@width).each do |col|
      @exit_r_and_d_counts << [row, col] if avail?(@height,col)
    end
    
  end

  def stringify_rows matrix
    (0..(matrix.size-1)).each do |y_val|
      matrix[y_val] = matrix[y_val].join
    end
    matrix
  end

  # fill-in dead-ends in the matrix w/ bombs
  def fill_in_dead_ends reverse=false
    if reverse
      (0..@height).each do |y_val|
        (0..@width).each do |x_val|
          next if y_val == 0 || x_val == 0 || fail(y_val, x_val)
  
          if fail( *Map.reverse_move(Robot.down, y_val,x_val) ) && fail( *Map.reverse_move(Robot.right, y_val,x_val) )
            # puts "filling-in a dead-end"
            @matrix[y_val][x_val] = Map.bomb
            
              # @bomb_hash["#{y_val}_#{x_val}"] = Map.bomb
            
            
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
            
            # @bomb_hash["#{y_val}_#{x_val}"] = Map.bomb
            
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

  def immediate_success(row,col)
    @row_success == row || @col_success == col
  end

  def success(row,col)
    row > @height || col > @width
  end

  #def array_fail(row,col)
  def fail(row,col)
    # @bomb_hash["#{row}_#{col}"] == Map.bomb
    @matrix[row][col] == Map.bomb
  end

  #def fail(row,col)
  #  @matrix[row].split(//)[col] == Map.bomb
  #end

  def safe?(row,col)
#puts "mr#{row}/c#{col}: #{@matrix[row].inspect}"
    #@matrix[row].split(//)[col] == Map.safe
#puts "ok"
    @matrix[row][col] == Map.safe
  end

  def self.reverse_move(direction, row, col, amount_down=1, amount_right=1)
    move direction, row, col, -1, -1
  end

  def self.move_up(row, col)
    row -= 1
    [row, col]
  end

  def self.move_down(row, col)
    row += 1
    [row, col]
  end

  def self.move_left(row, col)
    col -= 1
    [row, col]
  end

  def self.move_right(row, col)
    col += 1
    [row, col]
  end

  def self.move(direction, row, col, amount_down=1, amount_right=1)
    (direction == Robot.down) ? row += amount_down : col += amount_right
    [row,col]
  end

  def avail?(row,col)
    # immediate_success(row,col) || safe?(row,col)
    #! unavail?(row,col)
    @matrix[row][col] != Map.bomb
    # @bomb_hash["#{row}_#{col}"] != Map.bomb
    
  end
  
  #def unavail?(row,col)
  #  @matrix[row][col] == Map.bomb
  #rescue Exception => e
  #  return false
  #end

  # # append path to path, just checking the end-pts
  # def repeat_verify(num_down, num_right, row, col)
  #   row ||= num_down
  #   col ||= num_right
  # 
  #   begin
  #     return false if fail(row, col)
  #     row += num_down
  #     col += num_right
  #   end while !success(row,col)
  # 
  #   return true
  # end

  #
  # return a string of robot directions
  #
  def debug_verify(path_ary=[], row=0, col=0)
    puts "verifying path (from: r#{row}/c#{col}): #{path_ary.inspect}..."
    # path_down, path_across = *[row, col]
    while true # begin
      path_ary.each do |direction|
        row, col = *Map.move(direction, row, col)
        draw_matrix(row,col)
        # return true if immediate_success(row,col)
        return false if fail(row,col)
      end # end-each
      return true if success(row,col)
      
      # not sure why, but this early-return is WORKING; and FAST
      # return true
      # return repeat_verify(path_down, path_across, row, col)
    end # while true

    puts "dropping through..."
  rescue Exception => e
    return true
  end

  def fast_verify(path_ary=[], row=0, col=0)
    row = path_ary.count(Robot.down)
    col = path_ary.count(Robot.right)

    w_remainder = h_remainder = start_row = start_col = 0

    puts "path: #{path_ary}; Rdown: #{row}; Cright: #{col}"

    # how many times repeated to get within path_ary.size moves from edge?
    # path_loc = row + col
    
    # BUG: 
    # trying config: [0, 3]; 1 left
    # path: D; Rdown: 1; Cright: 0
    # num_high: 5
    # looking for: [5, 0] in [[5, 2]]
    # path: DR; Rdown: 1; Cright: 1
    # num_high: 5
    # looking for: [5, 5] in [[5, 2]]
    # num_wide: 5
    # looking for: [5, 5] in [[5, 2]]
    # path: DRD; Rdown: 2; Cright: 1
    # num_high: 2
    # looking for: [4, 2] in [[5, 2]] #<-- have to follow the path (upto) one-more cycle -- till we reach this square
    # it might be nice to identify the entry in path_ary that equates to the # or R's or D's needed; then test if coord matches
    # this is looking like too much work!
    # num_wide: 5
    # looking for: [4, 5] in [[5, 2]]
    # trying config: [4, 5]; 0 left
    # path: DRDDR; Rdown: 3; Cright: 2
    # num_high: 1
    # looking for: [3, 2] in [[5, 2]]
    # num_wide: 2
    # looking for: [3, 4] in [[5, 2]]
    # returning path: false

    if row != 0
      # puts "h: #{height}"
      num_high = (((@height + 1))) / (row) #how-many-more to go down
      puts "num_high: #{num_high}"
      start_row = row * num_high # after repeating path, where do we end-up
      
      # h_remainder = row ? (@height + 1) % row : 0
      
      if col != 0
        # num_wide = ((@width + 1)) / col
        start_col = col * num_high

        # what's the remainder (i.e such that we can append path_ary[remainder]) to get our exact exit
        # w_remainder = col ? (@width + 1) % col : 0
      end
      # should probably repeat this for going wide too
      
      potential_end = [start_row, start_col]
      puts "looking for: #{potential_end.inspect} in #{@exit_r_and_d_counts.inspect}"
      ret_val =  @exit_r_and_d_counts.include?(potential_end)
      return true if ret_val
    end
    # col:
    if col != 0
      # puts "h: #{height}"
      num_wide = (((@width + 1))) / (col) #how-many-more to go across
      puts "num_wide: #{num_wide}"
      start_col = col * num_wide # after repeating path, where do we end-up
            
      if row != 0
        # num_wide = ((@width + 1)) / col
        start_row = row * num_high

        # what's the remainder (i.e such that we can append path_ary[remainder]) to get our exact exit
        # w_remainder = col ? (@width + 1) % col : 0
      end
      # should probably repeat this for going wide too
      
      potential_end = [start_row, start_col]
      puts "looking for: #{potential_end.inspect} in #{@exit_r_and_d_counts.inspect}"
      ret_val =  @exit_r_and_d_counts.include?(potential_end)
      return true if ret_val
    end
    
    # rpt for col & row
    return false unless ret_val
    puts "hope..."    
    
    return non_recursive_verify(path_ary, row,col)


    # row = start_row
    # col = start_col
    # (0..w_remainder).each do |i|
    #   row, col = Map.move(path_ary[i], row, col)
    #   return false if fail(row,col)
    # end
    # 
    # row = start_row
    # col = start_col
    # (0..h_remainder).each do |i|
    #   row, col = Map.move(path_ary[i], row, col)
    #   return false if fail(row,col)
    # end
    # 
    # return non_recursive_verify(path_ary, start_row,start_col)

  end
  # alias :verify :fast_verify
    
  def non_recursive_verify(path_ary=[], row=0, col=0)
    # path_down, path_across = *[row, col]
    # reverse = path_ary.count(Robot.down) < path_ary.count(Robot.right)
    # success_check =  (ds > rs) ? lambda {|row| row > @height} : lambda {|col| col > @width}
    # puts "verify path_ary: #{path_ary}"
    while true # begin
      # path_ary.size.times do # is this useful ?so far no!?
      path_ary.each do |direction|
        row, col = Map.move(direction, row, col)
        return false if fail(row,col)
      end # end-each
      # end
      return true if success(row,col) # faster to do this single check than multiple checks
    end # while true
  end
  alias :verify :non_recursive_verify

  def recursive_verify(path_ary=[], row=0, col=0)
    path_ary.each do |direction|
      row, col = Map.move(direction, row, col)
      return false if fail(row,col)
    end # end-each
    return true if success(row,col) # faster to do this single check than multiple checks
    verify(path_ary, row, col)
  end

  def self.success
    'S' #made it to the border (assuming we expand the matrix...)
  end

  def self.boom
    'B' #the robot exploded
  end

  def self.bomb
    1 #'X'
  end

  def self.safe
    0 #'.'
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

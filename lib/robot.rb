require 'lib/map.rb'
class Robot
  attr_accessor :map, :path, :min, :max, :start_x, :start_y, :debug, :matrix

  #
  # this method gives the robots its marching orders
  # by default it will trigger the robot to "solve" the puzzle
  # (primarily because that's the API defined by runaway.rb)
  # options include:
  # :only_config  #<-- do not solve
  #
  def instruct(params={})
    puts "params: #{params.inspect}" if @debug
    options = {
      :board_x => 1,
      :board_y => 1,
      :ins_min => 0,
      :ins_max => 0
    }.merge(params)

    @start_x = 0
    @start_y = 0
    @cache_off = options[:cache_off]
    @min = options[:ins_min]
    @max = options[:ins_max]
	@map_terrain = options[:terrain_string]
	@map_width = options[:board_x] - 1
	@map_height = options[:board_x] - 1
    clear_path

    construct_matrix
    solve() if options[:only_config].nil?
  end

  def initialize(params={})
    @debug = params[:debug]
    params.delete(:debug)
    instruct(params) if params != {}
  end

  def clear_matrix
    @matrix = []
  end

  def construct_matrix
    next_cell = cell_generator
    clear_matrix
    (0..@map_height).each do |y_val|
      matrix_row = []
      (0 .. @map_width).each do |x_val|
        matrix_row << ('.' == next_cell.call ? 1 : 0 )
      end
      matrix_row << Robot.success
      @matrix << matrix_row
    end
    matrix_row = []
    (0 .. (@map_width + 1)).each do |x_val|
      matrix_row[x_val] = Robot.success
    end
    @matrix << matrix_row
  end

  #
  # return a char-by-char terrain iterator
  # :terrain_string=>"..X...X.."
  #
  def cell_generator
    terrain_ary = @map_terrain.split(//)
    i = -1
    lambda { i += 1; terrain_ary[i] }
  end
  
  def self.success
    2
  end
  
  def self.down
    'D'
  end
  
  def self.right
    'R'
  end
  
  def clear_path
    @path = []
  end

  #
  # come-up with a solution to the terrain-map
  # the idea for this method came from thinking about
  # logic truth-tables which spit-out T's & F's
  # to thinking about the CS tables of 1s & 0s
  # and, of course converting binary 1's & 0's
  # to D's & R's is easy
  #
  def solve
    # given an 'n' between min & max
    # total possible results: 2**n
    # a path can be constructed from binary values ranging from n-0's  .. n-1's
    # thus the values range from 0 - ((2**n)-1)
    # if the array is smaller than 'n', pad it w/ 0's
    # then, merely substitute D's for 0's and R's for 1's (or vice-versa)

    # here's a key piece of Ruby-Fu (did you know base-ten => binary was so
    # easy ?!):
    # (0 .. (n.size)).each { |slot| puts "slot: #{slot}: #{n[slot]}" }

    puts "solving..." if @debug
    next_move = []
    # even_move:
    mid_val = mid()
    if mid_val > @min
      next_move << path_generator(true,@min,mid_val)
      if @max > mid_val
        mid_val += 1
      end
    end
    # odd_move:
    next_move << path_generator(true,mid_val,@max)
    move_size = next_move.size

    # first check if we've already got a solution to this map...
    count = 0
    @path = map.lookup_solution(min(),max()) || []
    if [] == @path
      idx = move_size > 0 ? count % move_size : 0
      @path = next_move[idx] ? next_move[idx].call||[] : []
      count += 1
    else
      puts "found previous solution" #if @debug
      return
    end
    puts "trying path: #{@path.inspect}" if @debug

    until [] == @path || @map.verify(@start_x, @start_y,@path) do
      idx = move_size > 0 ? count % move_size : 0
      @path = next_move[idx] ? next_move[idx].call||[] : []
      count += 1
      while [] == @path && next_move.size > 0
        idx = move_size > 0 ? (count - 1) % move_size : 0
        next_move.delete_at(idx)
        move_size = next_move.size
        puts "at least one of the move-generators has yielded a nil; trying next"
        idx = move_size > 0 ? count % move_size : 0
        @path = next_move[idx] ? next_move[idx].call||[] : []
        puts "new path: #{@path.inspect}"
      end
      puts "trying path: #{@path.inspect}" if @debug
    end

    raise RuntimeError, "failed trying'" if [] == @path

    # if we got this far then we were successful
	if @debug
    	puts "solved."
	end

    # save this path to our solutions 'cache' file, for future use
    #@map.save(min(),max(),path()) unless @cache_off
  end

  #
  # a string version of the current path-array
  #
  def path
    @path.join
  end

  def mid(min=@min,max=@max)
    diff = max - min
    #return 1 if 0 == diff
    mid = min + (diff / 2)
    puts "mid: #{mid}"
    mid
    #min + ((max - min) / 2)
  end

  #
  # returns a lambda that keeps track & returns the next-possible 'path'
  #
  def path_generator(up=true,min=@min,max=@max)
    puts up ? "up from #{min} to #{max}" : "down from #{max} to #{min}"
    path_len = up ? min : max

    # we start at negative one ...but this gets incremented to 0
    base_ten = -1

    lambda do
      base_ten += 1
      if base_ten > ((2 ** path_len) - 1)
        path_len = up ? path_len + 1 : path_len - 1
        base_ten = 0
      end

      if (up && path_len <= max) || ((! up) && path_len >= min)
        # returns a path:
        binary_to_path(generate_binary(path_len, base_ten))
      else
        # all done
        nil
      end
    end
  end

  #
  # turn base-10 integer => binary ary
  #
  def generate_binary(num_digits, num)
    # append 0's if num.size is too small
    puts "generating #{num_digits} digit binary of #{num}..." if @debug
    (1 .. num_digits).map { |slot| num[(slot - 1)]||0 }
  end

  #
  # substitute R's & D's for 1's and 0's
  #
  def binary_to_path(binary_ary)
    puts "transforming binary: #{binary_ary.join}..." if @debug
    binary_ary.map {|digit| (digit == 0)? Robot.down() : Robot.right() }
  end

end

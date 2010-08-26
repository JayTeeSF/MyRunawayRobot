require './lib/map.rb'
class Robot
  attr_accessor :map, :path, :min, :max, :start_x, :start_y, :debug

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
      clear_path

      @map.config(options)

      # @map.draw_matrix(@start_x, @start_y)
      solve() if options[:only_config].nil?
    end

    def initialize(params={})
      @map = Map.new params
      @debug = params[:debug]
      params.delete(:debug)
      instruct(params) if params != {}
    end

    def self.prompt(msg="what?",options={})
      print msg + " "
      system "stty -echo" if options[:pwd]
      result = gets.chomp
      system "stty echo" if options[:pwd]
      puts ""
      return result
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

    # def gen_filtered_paths valid_down, valid_right
    #   results = []
    #   
    #   num_digits = valid_down + valid_right
    #   big_base_ten = 2**(num_digits) - 1
    #   
    #   (0..big_base_ten).each do |base_ten|
    #     path_ary = gen_path(base_ten,num_digits)
    #     results << path_ary if filter path_ary, valid_down, valid_right
    #   end
    #   
    #   results
    # end
    # 
    # def gen_path(base_ten,num_digits)
    #   (num_digits-1).downto(0).map {|slot| base_ten[slot] || 0}
    # end
    # 
    # # only return paths with correct destination coords
    # def filter path_ary, down, right
    #   path_ary.count(0) == right && path_ary.count(1) == down
    # end
    # 
    # def valid_destinations distance_away
    #   results = []
    #   # join.gsub(/1/,Robot.down()).gsub(/0/,Robot.right())
    #   (0 .. distance_away).each do |num_down|
    #     num_right = distance_away - num_down
    #     results << [gen_filtered_paths(num_down, num_right).map{|digit| (digit == 1) ? "D" : "R" }, num_down, num_right] if map.avail?(num_down,num_right)
    #   end
    #   
    #   results # represents valid paths
    # end

    # def solve
    #   valid_paths_and_coords = valid_destinations @min
    #   
    #   return false unless valid_paths_and_coords
    #   valid_paths_and_coords.each do |valid_path, row, col|
    #     path = solve_from valid_path, row, col
    #     return path if path
    #   end
    #   
    #   return false     
    # end

    def solve_from(current_path=[], row=0, col=0)
      # puts "called with: p:#{current_path}; r#{row}/c#{col}"
      path_size = current_path.size
      if path_size > @max
        # need to force code to undo last move...
        return false
      elsif path_size >= @min 
        if (map.debug) ? map.debug_verify(current_path, row, col) : map.verify(current_path, row, col)
puts "Found it (#{current_path.inspect})!"
          @path = current_path
          return @path
        end
      end

# puts "d: r#{row}/c#{col}"
      move = Map.move(Robot.down(),row,col)      
      if map.avail?(*move)
        current_path << Robot.down()
        solution = solve_from(current_path,*move)
        if solution
          return solution
        else
          current_path.pop
        end
      end

# puts "r: r#{row}/c#{col}"
      move = Map.move(Robot.right(),row,col)
      if map.avail?(*move)
        current_path << Robot.right()
        solution = solve_from(current_path,*move)
        if solution
          return solution
        else
          current_path.pop
        end
      end

# puts "<--"
      return false
    end
    alias :solve :solve_from

    #
    # a string version of the current path-array
    #
    def path
      @path.join
    end

  end
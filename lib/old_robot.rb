require 'lib/map.rb'
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

      @map.draw_matrix(@start_x, @start_y)
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

    def solve(current_path=[])

      if current_path.size >= @min
        if map.verify current_path
puts "Found it (#{current_path.inspect})!"
          @path = current_path
          return @path
        end
      end

      # need to force code to undo last move and try another option
      return false if current_path.size > @max

      row, col = *map.left_off(current_path)
# puts "d: r#{row}/c#{col}"
      if map.avail(Robot.down(), row,col)
        current_path << Robot.down()
        solution = solve(current_path)
        if solution
          return solution
        else
          current_path.pop
        end
      end

      row, col = *map.left_off(current_path)
# puts "r: r#{row}/c#{col}"

      if map.avail(Robot.right(), row,col)
        current_path << Robot.right()
        solution = solve(current_path)
        if solution
          return solution
        else
          current_path.pop
        end
      end

# puts "<--"
      return false
    end

    #
    # a string version of the current path-array
    #
    def path
      @path.join
    end

  end
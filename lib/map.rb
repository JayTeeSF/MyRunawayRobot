class Map
  BAD_CYCLE_LEN = 5
  #BAD_CYCLE_LEN = 3
  @@solutions = './solutions.txt'
  attr_accessor :height, :width, :terrain, :matrix, :debug, :known_bad_cycles, :use_known_bad, :store_bad, :check_bad, :bad_cycle_len

  def initialize(options={})
    @debug = options[:debug]
    @known_solutions = (options[:cache_off].nil?) ? load : Hash.new{|h, k| h[k]=Hash.new(&h.default_proc) }
    options.delete(:cache_off)
    options.delete(:debug)
    #puts "options: #{options.inspect}"
    config(options) if options && options != {}
  end

  #
  # Check to see if we've already solved this map (i.e. regardless of the
  # 'level')
  #
  def lookup_solution(min,max)
    ret_val = @known_solutions[@terrain][@height][@width][min][max]
    ret_val.class.to_s != 'Array' ? nil : ret_val
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
    @known_bad_cycles = []
    bad_cycle_len = nil

    # apparently this feature slows us down!!!
    @store_bad = false
    @use_known_bad = options[:use_known_bad] || true
    @check_bad = @use_known_bad

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
    return unless @debug
    construct_matrix unless @matrix
    if (row && col)
      # deep copy the array, before inserting our robot
      matrix = Marshal.load(Marshal.dump(@matrix))
      matrix[row][col] = (matrix[row][col] == Map.safe()) ? Map.robot() : Map.boom
    else
      matrix = @matrix
    end

    puts "\n#-->"
    matrix.each {|row| puts "#{row}"}
    puts "#<--\n"
  end

  def construct_matrix
    next_cell = cell_generator
    clear_matrix
    (0..height).each do |y_val|
      matrix_row = []
      (0 .. @width).each do |x_val|
        matrix_row << next_cell.call
      end
      @matrix << matrix_row
    end
  end

  #
  # return a char-by-char terrain iterator
  # :terrain_string=>"..X...X.."
  #
  def cell_generator
    terrain_ary = @terrain.split(//)
    i = -1
    lambda { i += 1; terrain_ary[i] }
  end

  def success(row,col)
    row > @width || col > @height
  end
  def fail(row,col)
    @matrix[row][col] == Map.bomb
  end

  def known_bad?(path_ary=nil)
    return true unless path_ary
    @known_bad_cycles.each do |cycle|
      max_idx = cycle.size - 1
      if path_ary[0..max_idx] == cycle
        puts "found bad cycle (#{cycle}) in #{path_ary}..." if @debug
        return true
      end
    end
    #puts "didn't find bad cycle...[#{@known_bad_cycles.inspect} vs.  #{path_ary.inspect}]"
    return false
  end

  #
  # return a string of robot directions
  #
  def verify(row=0, col=0, path_ary=[])
    if @check_bad
      return false if known_bad?(path_ary)
    end
    construct_matrix unless @matrix
    puts "verifying path: #{path_ary.inspect}..." if @debug

    verified = nil
    cycle_count = 1
    while true
    #!success(row,col) && !fail(row,col)

      path_ary.each do |move|
        case move
          when Robot.down
            row += 1
          else col += 1
        end #end-case

        # TODO: refactor this so we don't _also_ exit from within the loop
        if success(row,col)
          verified = true
          return verified
        elsif fail(row,col)
          verified = false
          if @store_bad
            bad_cycle = []
            cycle_count.times {bad_cycle << path_ary}
            bad_cycle.flatten!
            #puts "appending bad_cycle: #{bad_cycle.inspect}..."
            @known_bad_cycles << bad_cycle
          end
          return verified
        end
        #break unless verified.nil?
        draw_matrix(row,col)
      end # end-each
      cycle_count += 1

      if success(row,col)
        verified = true
          return verified
      elsif fail(row,col)
        verified = false
          if @store_bad
            bad_cycle = []
            cycle_count.times {bad_cycle << path_ary}
            bad_cycle.flatten!
            #puts "appending bad_cycle: #{bad_cycle.inspect}..."
            @known_bad_cycles << bad_cycle
          end
          return verified
      end
      #break unless verified.nil?
    end # end-while


    #if verified
    #  puts "passed verification" if @debug
    #else
    #  puts "failed verification" if @debug
    #end
    #return verified
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

  # 
  # restore known solutions, from file
  # TODO: actually use JSON (require 'JSON', etc...)
  # 
  def load(solutions=@@solutions)
    puts "returning hash of known solutions..." if @debug
    known_solutions = Hash.new{|h, k| h[k]=Hash.new(&h.default_proc) }
    if File.exists?(solutions)
      handle = File.open(solutions, 'r')
      while line = handle.gets
        puts "matching line: #{line}" if @debug
        m = /terrain \=\> ([^,]+), height \=\> (\d+), width \=\> (\d+), min \=\> (\d+), max \=\> (\d+), path \=\> (\w+)\s*$/.match(line)
        puts "m(#{m.class.to_s}): #{m.inspect}" if @debug
        known_solutions[m[0]][m[1]][m[2]][m[3]][m[4]] = m[5].split(//)
      end
    end
    known_solutions
  end

  #
  # append a known solution to our solutions-file
  # TODO: actually use JSON (require 'JSON', etc...)
  #
  def save(min, max, path_str, solutions=@@solutions)
    return false if lookup_solution(min,max)
    entry_str = "terrain => #{@terrain}," +
    " height => #{@height}, width => #{@width}," +
    " min => #{min}, max => #{max}," +
    " path => " + path_str

    File.open(solutions, "a") do |solutions_file|
      solutions_file.puts entry_str
    end
    return true
  end
  
end

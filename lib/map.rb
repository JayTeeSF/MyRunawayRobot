require './lib/nil_extensions.rb'

# for REE testing:
# require 'rubygems'
# require 'ruby-debug'

class Map
  attr_accessor :height, :width, :matrix, :robot, :map_folds

  module Colors
    ANSI_RED       = "\033[0;31m"
    ANSI_LRED      = "\033[1;31m"
    ANSI_GRAY      = "\033[1;30m"
    ANSI_LGRAY     = "\033[0;37m"
    ANSI_BLUE      = "\033[0;34m"
    ANSI_LBLUE     = "\033[1;34m"

    ANSI_BACKBLACK = "\033[40m"
    ANSI_BACKRED   = "\033[41m"
  end
  include Colors

  ANSI_REVERSE   = "\033[7m"
  ANSI_RESET      = "\033[0m"
  BM           = [[1]]

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

    # construct_matrix
  end

  def fill_matrix
    @matrix = construct_matrix
  end

  def clear_matrix
    @matrix = []
  end

  def self.path_to_coords(_matrix, path_ary, final_row, final_col)
    return [] if path_ary.empty?
    _height = Map.height(_matrix)
    _width = Map.width(_matrix)

    row, col = [0, 0]
    [].tap do |coords|
      coords << [row, col]
      while row < final_row && col < final_col
        path_ary.each do |direction|
          row, col = Map.move(direction, row, col)
          coords << [row, col]
        end
        # puts "#{coords.inspect}"
      end # while
    end # tap
  end

  # human readable
  def draw_matrix(_matrix=nil, row=nil,col=nil, path_ary=[])
    coord_path = Map.path_to_coords(_matrix, path_ary, row, col)
    # puts "coord_path: #{coord_path.inspect} vs. path_ary: #{path_ary.inspect}" unless coord_path.empty?
    # return unless @debug
    if _matrix.nil?
      # puts "nil matrix"
      clear_matrix
      _matrix = fill_matrix
    elsif _matrix.empty? # someone else's matrix ?!
      puts "empty matrix"
      _matrix = construct_matrix( _matrix ) # no fill-in, here
    end
    # puts "drawing: _matrix: #{_matrix.inspect}"

    # deep-copy the array, before any (potential) modifications
    _this_matrix = Map.map_dup(_matrix)

    if (row && col) # insert the Robot
      # puts "_this_m: #{_this_matrix.inspect}"
      _this_matrix[row] ||= []
      _this_matrix[row][col] = (_this_matrix[row][col] == Map.safe()) ? Map.robot() : Map.boom
      # puts "_this_m: #{_this_matrix.inspect}"
    end

    puts "\n#-->"
    _this_matrix.each_with_index do |current_row,i|
      next unless current_row # probably need a way to capture the robot's extra-matric-steps :-o
      current_row.each_with_index do |e,j|
        current_distance = Map.distance(i, j)

        if Map.boom() == e
          current_row[j] =   "#{ANSI_RED}B#{ANSI_RESET}"
          next
        end

        if Map.robot() == e
          current_row[j] =   "#{ANSI_RED}R#{ANSI_RESET}"
          next
        end

        color = ''

        if current_distance < robot.min
          if (e == 1)
            current_row[j] = '+'
          else
            color = ANSI_LBLUE
            current_row[j] = '.'
          end
        elsif (current_distance % robot.max) == 0 && (current_distance % robot.min) == 0
          if (e == 1)
            current_row[j] = '^'
            color = ANSI_REVERSE
          else
            color = ANSI_REVERSE
            current_row[j] = '`'
          end
        elsif (current_distance % robot.min) == 0
          if (e == 1)
            color = ANSI_REVERSE
            current_row[j] = '>' 
          else
            color = ANSI_REVERSE
            current_row[j] = '`'
          end
        elsif current_distance > robot.min && current_distance < robot.max
          if (e == 1)
            current_row[j] = '/'
          else
            color = ANSI_BLUE
            current_row[j] = '`'
          end
        elsif (current_distance % robot.max) == 0
          if (e == 1)
            color = ANSI_REVERSE
            current_row[j] ='<'
          else 
            color = "#{ANSI_REVERSE}#{ANSI_BLUE}"
            current_row[j] ='`'
          end
        else
          if (e == 1)
            current_row[j] = "+" 
          else
            current_row[j] = "." 

            color = ANSI_LGRAY
          end
        end

        if coord_path.include?([i, j])
          color = ANSI_RED
        end

        current_row[j] = "#{color}#{current_row[j]}#{ANSI_RESET}"
      end
      puts "#{current_row * ' '}"
    end
    puts "#<--\n"

    # rescue Exception => e
    #   puts "Unable to display this matrix: #{e.message}"
  end

  def construct_matrix(_matrix=[], next_cell=cell_generator, _height=@height, _width=@width)
    # puts "constructing matrix..."
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

    fill_in_dead_ends( _matrix )
  end

  def coord_generator(row, col)
    new_row = row; new_col = col
    lambda do
      [new_row, new_col].tap do
        new_row += row
        new_col += col
      end
    end
  end

  # 
  # perhaps we can fold the map, so we only have to verify one-segment of path
  # update one quadrant w/ the constraints of all others
  # call this from Robot's init method, for the (min-) start-pts...
  # 
  def fold_map(row, col)
    # puts "folding..."
    @map_folds["#{row}_#{col}"] ||= generate_fold(row, col)
  end

  def identity_matrix(_height, _width)
    [].tap do |_matrix|

      (0).upto(_width) do |c_val|
        (0).upto(_height) do |r_val|
          _matrix[r_val] ||= []
          _matrix[r_val][c_val] = Map.safe
        end # r_val
      end # c_val

    end # tap
  end

  def generate_fold(row, col)
    # puts "gen(#{row}/#{col})"
    next_coord = coord_generator(row, col)
    # init:
    _matrix = identity_matrix(row, col)
    big_matrix = matrix.dup
    # puts "\ninit-matrix: #{_matrix.inspect}"

    # keep generating next-coord
    # then loop over _matrix, and fill-in any bombs from big-matrix
    # that exist at _r + current_coord and _c + current_coord
    _height = Map.height(_matrix)
    _width = Map.width(_matrix) 

    big_matrix_row = 0
    big_matrix_col = 0
    current_coord = [0, 0] # [row, col]
    begin

      (0).upto(_width) do |c_val| # width
        big_matrix_col = c_val + current_coord.last

        (0).upto(_height) do |r_val| # height
          big_matrix_row = r_val + current_coord.first

          # print "\ntransposing: #{big_matrix_row}/#{big_matrix_col} (#{matrix[big_matrix_row][big_matrix_col]}) => #{r_val}/#{c_val}"
          if Map.bomb == big_matrix[big_matrix_row][big_matrix_col]
            # puts " ..."
            _matrix[r_val][c_val] = Map.bomb
          end

        end # end-height
      end # end-width
      current_coord = next_coord.call # += r, c
      # puts "current_coord: #{current_coord.inspect}"

    end until success?(*current_coord) # success in one-direction is not sufficient ?!?

    return BM if Map.bm? _matrix

    # puts "matrix: #{_matrix.inspect}"

    # first block-out any bottom/right cells that can't reach the corner...
    _matrix = fill_in Map.mark_invalid_spots(_matrix, _height, _width)

    return BM if Map.bm? _matrix
    _matrix

  end

  def fill_in(_matrix, count=1)
    _height = Map.height(_matrix)
    _width = Map.width(_matrix) 

    new_m = []
    _matrix = construct_matrix( new_m, cell_generator( Map.matrix_to_ary( _matrix ) ), _height, _width )

    count -= 1
    return count <= 0 ? _matrix : fill_in( _matrix, count )
  end

  # fill-in dead-ends in the matrix w/ bombs
  def fill_in_dead_ends _matrix=@matrix, direction=:both
    _height = Map.height(_matrix)
    _width = Map.width(_matrix) 

    if :both == direction || :reverse == direction #reverse
      (0).upto(_height) do |y_val|
        (0).upto(_width) do |x_val|
          next if y_val == 0 || x_val == 0 || Map.fail?(y_val, x_val, _matrix)
          dr, dc = Map.reverse_move(Robot.down, y_val, x_val)
          rr, rc = Map.reverse_move(Robot.right, y_val, x_val)
          if Map.fail?( dr, dc, _matrix ) && Map.fail?( rr, rc, _matrix )
            # puts "filling-in a dead-end"
            _matrix[y_val][x_val] = Map.bomb
          end
        end
      end
    end

    if :both == direction || :forward == direction# forward
      _height.downto(0) do |y_val|
        _width.downto(0) do |x_val|
          next if y_val == _height || x_val == _width || Map.fail?(y_val, x_val, _matrix)
          dr, dc = Map.move(Robot.down, y_val, x_val)
          rr, rc = Map.move(Robot.right, y_val, x_val)
          if Map.fail?( dr, dc, _matrix ) && Map.fail?( rr, rc, _matrix )
            # puts "filling-in a dead-end"
            _matrix[y_val][x_val] = Map.bomb
          end
        end
      end
    end

    _matrix
  end

  #  def non_recursive_verify(path_ary=[], row=0, col=0)
  def verify(path_ary=[], row=0, col=0)
    start_row = row; start_col = col

    # puts "verifying..."
    draw = ! @map_folds["#{row}_#{col}"]
    _matrix = fold_map(row,col)

    if BM == _matrix
      return false
    end

    row = col = 0
    draw_matrix(_matrix, row, col) if draw

    if Map.fail?(row, col, _matrix)
      # puts "hit a bomb at start of first/second pass-through"
      return false
    end

    _height = Map.height(_matrix)
    _width = Map.width(_matrix)
    while ! Map.success?( row, col, _height, _width )
      path_ary.each do |direction|
        row, col = Map.move(direction, row, col)
        if Map.fail?(row, col, _matrix)
          # puts "hit a bomb at start of first/second pass-through"
          return false
        end
      end # end-each
      puts "p"
    end

    #   # if we made it through the folded matrix --then we're good!
    # puts "recursive-verify!"
    puts "!: #{start_row}/#{start_col}"
    #: #{path_ary.inspect}"
    return recursive_verify(path_ary, start_row, start_col)
  end

  # this only operates on the _big_ matrix
  def recursive_verify(path_ary=[], row=0, col=0)
    # print "v"
    if success?(row,col) # faster to do this single check than multiple checks
      draw_matrix(@matrix, row, col, path_ary)
      return true
    end
    path_ary.each do |direction|
      if fail?(row, col)
        return false
      end
      row, col = Map.move(direction, row, col)
    end # end-each
    recursive_verify(path_ary, row, col)
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
    lambda { i += increment; terrain_ary[i].to_i }
  end

  def success?(row, col)
    Map.success?(row, col, @height, @width)
  end  

  def fail?(row, col)
    Map.fail?(row, col, @matrix)
  end

  def avail?(row,col, _matrix=@matrix)
    ! Map.fail?(row, col, _matrix)
  end  

  def self.success?(row, col, _height, _width)
    row > _height || col > _width
  end

  def self.fail?(row, col, _matrix)
    Map.bomb == _matrix[row][col] #1; have nil_extensions handle out-of-bound issues
  end

  def self.mark_invalid_spots _matrix, _height=nil, _width=nil
    _height ||= Map.height(_matrix)
    _width ||= Map.width(_matrix) 

    mark_invalid_bottom_spots(mark_invalid_right_spots( map_dup(_matrix), _height, _width ), _height, _width )
  end

  def self.mark_invalid_right_spots _matrix, _height=nil, _width=nil
    _height ||= Map.height(_matrix)
    _width ||= Map.width(_matrix) 

    coords = Map.valid_right_coords(_matrix) || []
    coords.each do |coord|
      row, col = coord
      _matrix[row][col] = Map.bomb unless Map.down_from_here?(row, col, _matrix, _height, _width)
    end
    _matrix
  end

  def self.mark_invalid_bottom_spots _matrix, _height=nil, _width=nil
    _height ||= Map.height(_matrix)
    _width ||= Map.width(_matrix) 

    coords = Map.valid_bottom_coords(_matrix) || []
    coords.each do |coord|
      row, col = coord
      _matrix[row][col] = Map.bomb unless Map.right_from_here?(row, col, _matrix, _height, _width)
    end
    _matrix
  end

  def self.down_from_here?(row, col, _matrix, final_row, final_col)
    return false unless col == final_col
    until row == final_row
      return false if Map.bomb == _matrix[row][col]
      row, col = Map.move(Robot.down(), row, col)      
    end
    return (Map.bomb == _matrix[row][col]) ? false : true
  end

  def self.right_from_here?(row, col, _matrix, final_row, final_col)
    return false unless row == final_row
    until col == final_col
      return false if Map.bomb == _matrix[row][col]
      row, col = Map.move(Robot.right(), row, col)
    end
    return (Map.bomb == _matrix[row][col]) ? false : true
  end

  def self.robot
    'R'
  end

  def self.matrix_to_ary( _matrix )
    [].tap do |ary|
      _matrix.each do |row|
        row.each do |element|
          ary << element
        end # col
      end # row
    end # tap
  end

  def self.distance(row, col)
    row + col
  end

  def self.map_dup(_matrix)
    Marshal.load(Marshal.dump(_matrix))
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

  def self.valid_right_coords(_matrix)
    right_coords(_matrix).delete_if {|r,c| Map.fail?(r, c, _matrix)}
  end
  
  def self.valid_bottom_coords(_matrix)
    bottom_coords(_matrix).delete_if {|r,c| Map.fail?(r, c, _matrix)}
  end
  
  def self.right_coords(_matrix)
    _height = Map.height(_matrix)
    _width = Map.width(_matrix) 
  
    col = _width
    [].tap do |coords|
      (0).upto(_height) do |row|
        coords << [row, col]
      end # rows
    end # tap
  end
  
  def self.bottom_coords(_matrix)
    _height = Map.height(_matrix)
    _width = Map.width(_matrix) 
  
    row = _height
    [].tap do |coords|
      (0).upto(_width) do |col|
        coords << [row, col]
      end # rows
    end # tap
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

  def self.height(_matrix)
    _matrix.size - 1
  end

  def self.width(_matrix)
    _matrix.first.size - 1
  end

  def self.bm?(_matrix)
    ( Map.bomb == _matrix[1][0] && Map.bomb == _matrix[0][1] ) ||
    Map.bomb == _matrix[0][0] ||
    Map.bomb == _matrix[height(_matrix)][width(_matrix)]
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
end

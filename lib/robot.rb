require './lib/map.rb' # for 1.9.2
# require 'lib/map.rb' # for rbx
require 'thread'  # For Mutex class in Ruby 1.8

class Robot
  attr_accessor :map, :path, :min, :max, :min_size, :start_x, :start_y, :debug

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
      @min_size = @min - 1
      @max = options[:ins_max]
      clear_path

      @map.config(options)

      # @dt_count = 0
      # @do_count = 0       

      @map.draw_matrix(@start_x, @start_y)
      solve() if options[:only_config].nil?
    end

    def initialize(params={})
      @map = Map.new params
      @debug = params[:debug]
      @dir_one = nil
      @dir_two = nil
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

    def direction(idx)
      (0 == idx) ? Robot.down() : Robot.right()
    end

    def dir_to_num(direction)
      Robot.down() == direction ? 0 : 1
    end

    # require './lib/robot.rb'
    # robot = Robot.new
    # robot.map.matrix = [%w[ . . X ], %w[ X . . ], %w[ . X . ] ]
    # robot.find_avail_cells 2
    #  => [[1, 1], [2, 0]] # notice no: [0, 2]!
    def find_avail_cells(n_away, row=0, col=0)
      (0 .. n_away).collect do |x_val|
        y_val = n_away - x_val
        map.avail?(row + x_val, col + y_val) ? [row + x_val, col + y_val] : nil
      end.compact
    end

    # what if we only traverse the avail-cells (i.e. use find_avail_cells to pick next move ?!)

    # can we traverse backwards (i.e. to make finding the "longer"-paths, faster ?!)
    # or perhaps we can remember the previous paths ...and then append the longer ones...

    def calculate_move(current_path=[], row=0, col=0)
      # current_path.each do |direction|
      #         row, col = Map.move(direction, row, col) # this is slow!
      #       end
      #       [row, col]
      extract_moves(current_path, row, col).last
    end

    def extract_moves(current_path=[], row=0, col=0)
      current_path.collect do |direction|
        Map.move(direction, row, col)
      end
    end

    # can we get rid of move_hist & dir_hist, and just calculate the row, col values, as needed
    def solve_non_recursive(current_path=[], row=0, col=0, path_min=@min_size,path_max=@max)	    
      # move_hist, dir_history = extract_moves_and_dirs(current_path, row, col)
      # move_hist = extract_moves(current_path, row, col) #lastest-removed
      # puts "move_hist: #{move_hist.inspect}"
      # direction_history = BitField.new(map.max_cycle * 2)
      # dir_idx = dir_history.pop || 0
      # puts "current_path.last: #{current_path.last}"
      dir_idx = current_path.last ? dir_to_num(current_path.last) : 0
      # puts "dir_idx: #{dir_idx}"
      path_size = current_path.size
      while true
        # sleep 0.00001

        # puts "cp:#{current_path}; r#{row}/c#{col}"
        if path_size > path_min #@min_size
          if path_size > path_max # @max
            # dir_idx, dir_history, current_path, move_hist = backup(dir_history, current_path, move_hist) #, row, col) 
            current_path, row, col = backup(current_path)
            # current_path, row, col, move_hist = backup(current_path, move_hist)
            # row, col = move_hist.last
            path_size = current_path.size
            return false if 0 == path_size
            dir_idx = 1; # puts "^" # try a different direction
          elsif map.verify(current_path, row, col)
            puts "Found it (#{current_path.inspect})!"
            # @path = current_path
            # return @path
            return current_path
          end
        end

        # puts "#{direction(dir_idx)}: r#{row}/c#{col}"
        move = Map.move(direction(dir_idx),row,col) # this could be down/right!!!
        avail = map.avail?(*move)

        if ! avail && 0 == dir_idx
          dir_idx = 1; # puts "^" # try opposite direction
          move = Map.move_right(row,col) # this _is_ right!!!
          avail = map.avail?(*move)
        end

        if avail
          # puts "."
          # dir_history << dir_idx
          current_path << direction(dir_idx)
          # move_hist << move
          path_size += 1
          row, col = move
          dir_idx = 0
        else
          # backup; we've already tried both directions
          # dir_idx, dir_history, current_path, move_hist = backup(dir_history, current_path, move_hist) #, row, col)
          # row, col = move_hist.last
          current_path, row, col = backup(current_path)
          # current_path, row, col, move_hist = backup(current_path, move_hist)
          path_size = current_path.size
          return false if 0 == path_size
          dir_idx = 1; # puts "^" # try different direction
        end

      end # end while loop
    end
    #alias :solve :solve_non_recursive


    # def backup(dir_history, current_path, move_hist) #, row, col)
    def backup(current_path)
      # def backup(current_path, move_hist)
      while current_path.pop == Robot.right()
        # move_hist.pop
      end
      # begin
      #   # dir_idx = dir_history.pop
      #   # print "-"
      #   dir_idx = dir_to_num(current_path.pop)
      #   # current_path.pop
      #   #row, col = move_hist.pop
      #   # move_hist.pop
      #   # row, col = Map.reverse_move(direction(dir_idx),row,col)
      # end while 1 == dir_idx # keep shortening... till we find take a turn we haven't tried
      # puts ""
      # [dir_idx, dir_history, current_path, move_hist] #, row, col]

      # [current_path, *calculate_move(current_path)]
      # row, col = move_hist.pop
      # [current_path, row, col, move_hist]
      [current_path, current_path.count(Robot.down), current_path.count(Robot.right)]
    end

    # def dir_two=(dir)
    #   @dir_two = dir
    # end
    # 
    # def dir_one=(dir)
    #   @dir_one = dir
    # end

    def dir_one
      # @dir_one ||= 
      Robot.down()
    end

    def dir_two
      # @dir_two ||= 
      Robot.right()
    end

    def solve_recursive(current_path=[], row=0, col=0, path_min=@min_size,path_max=@max)
      #puts "params: pn: #{path_min}, px: #{path_max}"
      # puts "d_o = #{dir_one}; d_t: #{dir_two}"
      # puts "called with: p:#{current_path}; r#{row}/c#{col}"
      path_size = current_path.size
      # sleep 0.00001

      if path_size > path_min #@min_size
        if path_size > path_max # @max
          # @dt_count += current_path.count(dir_two)
          # @do_count += current_path.count(dir_one)
          # @start_path ||= current_path
          # @start_row ||= row
          # @start_col ||= col
          return false
        elsif map.verify(current_path, row, col)
          puts "Found it (#{current_path.inspect})!"
          # @path = current_path
          # return @path
          return current_path
        end
      end

      # puts "d: r#{row}/c#{col}"
      move = Map.move(dir_one,row,col)      
      if map.avail?(*move)
        current_path << dir_one
        r, c = *move
        solution = solve_recursive(current_path,r,c, path_min, path_max)
        if solution
          return solution
        else
          current_path.pop
        end
      end

      # puts "r: r#{row}/c#{col}"
      move = Map.move(dir_two,row,col)
      if map.avail?(*move)
        current_path << dir_two
        r, c = *move
        solution = solve_recursive(current_path,r,c, path_min, path_max)
        if solution
          return solution
        else
          current_path.pop
        end
      end

      # puts "<--"
      return false
    end

    # (size)
      # @path_min ? @path_min += 1 : @path_min = @min_size
      # @path_max = @path_min + 1
      #ranges = (@min_size .. (@max - ideal_range)).collect do |i|
      #  [i, i + ideal_range]
      #end

#      puts "trying #{size}..."
#      a_bit = one_bit
#      a_bit = one_bit > 1 ? one_bit : 1
#      a_fourth = a_bit * 2 #one_fourth
#
#      puts "a_bit: #{a_bit}; a_fourth: #{a_fourth}"
#      case size
#      when :xsmall
#        path_min = @min_size
#        path_max = @min_size + a_fourth
#      when :small
#        path_min = @min_size + a_fourth + 1 #- 1
#        path_max = mid
#      when :med
#        path_min = mid + 1 #- 1
#        path_max = mid + a_fourth
#      when :large
#        path_min = mid + a_fourth + 1
#        path_max = @max #- 1
#      end


      #   path_max = @max - a_fourth #mid + a_fourth + a_bit #- 1
      # when :xlarge
      #   path_min = @max - a_fourth + 1 #mid + a_fourth + a_bit + 1

      # 
      # case size
      # when :xxsmall
      #   @path_min = @min_size
      #   @path_max =  @min_size + a_bit
      # when :xsmall
      #   @path_min = @min_size + a_bit #- 1
      #   @path_max = @min_size + a_fourth
      # when :small
      #   @path_min = @min_size + a_fourth #- 1
      #   @path_max = @min_size + a_fourth + a_bit
      # when :medsmall
      #   @path_min = @min_size + a_fourth + a_bit #- 1
      #   @path_max = mid
      # when :med
      #   @path_min = mid #- 1
      #   @path_max = mid + a_bit
      # when :large
      #   @path_min = mid + a_bit #- 1
      #   @path_max = mid + a_fourth
      # when :xlarge
      #   @path_min = mid + a_fourth
      #   @path_max = mid + a_fourth + a_bit #- 1
      # when :xxlarge
      #   @path_min = mid + a_fourth + a_bit
      #   @path_max = @max #- 1
      # end

      # [path_min, path_max]

    def solve
      # sizes = [ :xxsmall, :xsmall, :small, :medsmall, :med, :large, :xlarge, :xxlarge ]
#      #sm_sizes = [ :xsmall, :med, :small]
#      #lg_sizes= [:large]

      # need to pre-calculate the sizes...
#      #sm_size_configs = sm_sizes.collect {|size| x = config(size); puts "#{size} => #{x.inspect}"; x}
#      #lg_size_configs = lg_sizes.collect {|size| x = config(size); puts "#{size} => #{x.inspect}"; x}

      # sizes = sm_sizes + lg_sizes
#      all_size_configs = sm_size_configs + lg_size_configs
      all_size_configs = config()
      result = false

      # last non-threaded version:
      # puts "configs: #{all_size_configs.inspect}"
      # while ((! result) && all_size_configs.size > 0)
      #   result = solve_recursive(current_path=[], row=0, col=0,*all_size_configs.shift)
      # end


# multiprocess may be better (easier)/more scalable: IO.pipe ?!
# cmd = "ruby -e '5.times {|i| p i}'"
# output = `#{cmd}` # how do we avoid blocking ?!
# puts output
# 0
# 1
# 2
# 3
# 4
# 
# self.map.matrix = [[1,2,3],[4,5,6],[7,8,9]]
# puts self.map.matrix.inspect # => [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

### BGN MULTIPROCESS
if all_size_configs.first == all_size_configs.last
  all_size_configs = [all_size_configs.first]
  all_size_configs_reverse = all_size_configs.dup.reverse
else
  all_size_configs_reverse = all_size_configs[1..-1].dup.reverse
end
proc_hash = {}
pipes = {} # key1 => [rd, wr], key2 => ...

puts "lg-configs: #{all_size_configs_reverse.inspect}"

# how-to associate rd/wr pipes w/ the different procs?
# how-to check each child-proc (and not confuse their pipes)

# lg_rd, lg_wr = IO.pipe
key = :lg_pid
pipes[key] = IO.pipe
proc_hash[key] = fork {
  pipes[key].first.close
  result = false
  while ((! result) && (all_size_configs_reverse.size > 0))
    config = all_size_configs_reverse.shift
    puts "lg-trying config: #{config.inspect}; #{all_size_configs_reverse.size} left"
    result = solve_recursive([], 0, 0,*config)          
  end
  pipes[key].last.write result ? result : "false"
  pipes[key].last.close
  puts "thread large DONE"
}
pipes[key].last.close


if all_size_configs.size > 1

  key = :sm_pid
  pipes[key] = IO.pipe
  final_range_min, final_range_max = *all_size_configs[-1]
  puts "final_range: #{final_range_min}:#{final_range_max}"
  final_range_chunks = config(final_range_min, final_range_max,1)
  
  puts "final_range_chunks: #{final_range_chunks.inspect}"
  all_size_configs = all_size_configs[0..-2]
  all_size_configs << final_range_chunks # [@max - 1, @max]
  puts "sm-configs: #{all_size_configs.inspect}"

  proc_hash[key] = fork {
    pipes[key].first.close
    result = false
    while ((! result) && (all_size_configs.size > 0))
      config = all_size_configs.shift
      puts "sm-trying config: #{config.inspect}; #{all_size_configs.size} left"
      result = solve_recursive([], 0, 0,*config)         

    end
    pipes[key].last.write result ? result : "false"
    pipes[key].last.close
    puts "thread small DONE"
  }

  pipes[key].last.close
  
end

deleted_pids = []

while ((!result) && (deleted_pids.size < proc_hash.keys.size))
  proc_hash.each do |key, pid|
    next if deleted_pids.include?(pid)
    if Process.waitpid(proc_hash[key], Process::WNOHANG)   #=> nil
      deleted_pids << pid
      
      # rd.read
      result = pipes[key].first.read
      result = (result == "false") ? false : result.split(//)

      puts "result is now: #{result.inspect}"
      
      # rd.close
      pipes[key].first.close

    end

  end #each pid
end # end while not-result
puts "done while loop"

# Kill remaining procs
proc_hash.each do |key,pid|
  next if deleted_pids.include?(pid)
  Process.kill("KILL", pid)
  deleted_pids << pid
end

puts "deleted all pids: #{deleted_pids.inspect} <=> #{proc_hash.inspect}"

### END MULTIPROCESS

#       ### BGN THREADED
#       all_size_configs_reverse = all_size_configs[1..-1].dup.reverse
#       thread_ary = []
#       puts "lg-configs: #{all_size_configs_reverse.inspect}"
#       
#       thread_ary[thread_ary.size] = Thread.new do
#         Thread.current["result"] = false
#         while ((! Thread.current["result"]) && (all_size_configs_reverse.size > 0))
#           config = all_size_configs_reverse.shift
#           puts "lg-trying config: #{config.inspect}; #{all_size_configs_reverse.size} left"
#           Thread.current["result"] = solve_recursive([], 0, 0,*config)          
#         end
#         puts "thread large DONE"
#       end
#       
#       if all_size_configs.size > 1
#         all_size_configs = all_size_configs[0..-2]
#         puts "sm-configs: #{all_size_configs.inspect}"
#         
#         thread_ary[thread_ary.size] = Thread.new do
#           Thread.current["result"] = false
#           while ((! Thread.current["result"]) && (all_size_configs.size > 0))
#             config = all_size_configs.shift
#             puts "sm-trying config: #{config.inspect}; #{all_size_configs.size} left"
#             Thread.current["result"] = solve_recursive([], 0, 0,*config)
#           end
#           puts "thread small DONE"
#         end
#       end
# 
#       # if we run out of threads || we get a result STOP
#       thread_ary_size = thread_ary.size
#       deleted_threads = []
#       until thread_ary_size <= 0 || result
#         sleep 0.01
#         thread_ary.each_with_index do |thr,i|
#           next if deleted_threads.include?(i)
# 
#           if ! thr.status
#             # puts "thread_ary.size was: #{thread_ary.size} vs. #{thread_ary_size}"
#             # thread_ary.delete(i) # BAD modifying loop-xxx... doesn't work
#             unless deleted_threads.include?(i)
#               thread_ary_size -= 1
#               deleted_threads << i
#               puts "deleted thread: #{i}"            
#             end
# 
#             if thr && thr["result"]
#               #got what we wanted
#               result = thr["result"]
#             end # if got result
#             
#             # puts "calling break..."
#             break
# puts "never here?!"
#           end # if thread done
# # puts "end of for-loop"
#         end # loop through threads
# # puts "end of while-loop"
#       end # while
# 
#       #kill all other threads
#       thread_ary.each {|thr| thr.kill }
#       ### END THREADED

      @path = result
      puts "returning path: #{@path}\n";
      return result
    end


    # use # of bombs scattered in lower right portion of graph to determine size-ordering (?!)

    #sizes = [ :small, :xlarge, :large, :med ]
    #if @map.width < 32
    #  sizes = [:small, :med, :large, :xlarge]
    #elsif @map.width > 32
    #  sizes = [:med, :small, :large, :xlarge]
    #elsif @map.width > 64
    #  sizes = [:med, :large, :small, :xlarge]
    #end
    # puts "trying sizes: #{sizes.inspect}"

    # # @path_max = 0
    # # @start_path = []; @start_row = @start_col = 0
    # while ((! result) && sizes.size > 0) # @path_max < @max
    #   # dt_diff = @dt_count - @do_count
    #   # if dt_diff > 0.3 * @do_count
    #   #   puts "swapping to dt(#{dir_two}), first..."
    #   #   tmp_dir = dir_one
    #   #   @dir_one = dir_two
    #   #   @dir_two = tmp_dir
    #   #   puts "ok: dir_two: #{dir_two}; dir_one: #{dir_one}"
    #   # end
    #   # @dt_count = @do_count = 0
    # 
    #   if diff < 10
    #     @path_min = @min_size
    #     @path_max = @max
    #     sizes = []
    #   else
    #     config(sizes.shift)
    #   end
    #   puts "#{@min_size} >> #{@path_min} - #{@path_max} << #{@max}"
    #   # result = solve_recursive() # @start_path, @start_row, @start_col)
    #   result = solve_non_recursive() # @start_path, @start_row, @start_col)
    # end
    # 
    # sizes = [:xsmall, :small, :med, :large, :xlarge]

    def config(a_min=@min_size,a_max=@max,ideal_range=3)

      total_range = diff(a_min,a_max)

      return [[a_min, a_max]] if total_range <= ideal_range

      ranges = []
      r_min = a_min
      r_max = r_min + ideal_range
      while ((r_max <= a_max) && (r_min < a_max))
        puts "adding: #{r_min}:#{r_max}"
        ranges << [r_min,r_max]
        r_min += (ideal_range + 1)
        
        if r_min >= a_max
          r_min = r_max # former max
          r_max = a_max # final max
        else
          r_max = r_min + ideal_range
          if r_max > a_max
            r_max = a_max # final max
          end
        end
      end

      ranges
    end

    def diff(a_min=@min_size,a_max=@max)
      a_max - a_min
    end
    # distance:
    def mid(a_min=@min_size,a_max=@max)
      a_min + half(a_min, a_max)
    end

    # amount:
    # an eighth:
    def one_eighth(a_min=@min_size,a_max=@max)
      one_fourth(a_min, a_max) / 2
    end
    alias :one_bit :one_eighth

    # require './lib/robot.rb'
    # r = Robot.new
    # r.min = 3
    # r.min_size = 2
    # r.max = 10

    # amount
    def half(a_min=@min_size,a_max=@max)
      diff(a_min, a_max) / 2
    end

    def one_fourth(a_min=@min_size,a_max=@max)
      half(a_min, a_max) / 2
    end

    #
    # a string version of the current path-array
    #
    def path
      @path.join
    end

  end

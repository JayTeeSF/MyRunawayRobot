require './lib/map.rb' # for 1.9.2
# require 'lib/map.rb' # for rbx
# require 'thread'  # For Mutex class in Ruby 1.8

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

      # @dt_count = 0
      # @do_count = 0       

      @map.draw_matrix(@start_x, @start_y)
      solve() if options[:only_config].nil?
    end

    def initialize(params={})
      @map = Map.new params
      @debug = params[:debug]
      # @dir_one = nil
      # @dir_two = nil
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
    def solve_non_recursive(current_path=[], row=0, col=0, path_min=@min,path_max=@max)	    
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
        sleep 0.001

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

    # def dir_one
    #   # @dir_one ||= 
    #   Robot.down()
    # end
    # 
    # def dir_two
    #   # @dir_two ||= 
    #   Robot.right()
    # end

    def solve_recursive(current_path=[], row=0, col=0, path_min=@min,path_max=@max)
      path_size = current_path.size
      if path_size > path_min #@min_size
        if path_size > path_max # @max
          return false
        elsif map.verify(current_path, row, col)
          puts "Found it (#{current_path.inspect})!"
          return current_path
        end
      end

      # puts "d: r*#{row}/c#{col}"
      move = Map.move(Robot.down(), row, col)      
      if map.avail?(*move)
        r, c = *move
        sol_path = current_path.dup
        sol_path << Robot.down()
        solution = solve_recursive(sol_path, r, c, path_min, path_max)
        if solution
          return solution
        # else
        #   current_path.pop
        end
        # puts "sol_path #{sol_path} vs. curr #{current_path}"
      end

      # puts "r: r#{row}/c*#{col}"
      move = Map.move(Robot.right(), row, col)
      if map.avail?(*move)
        r, c = *move
        sol_path = current_path.dup
        sol_path << Robot.right()
        solution = solve_recursive(sol_path, r, c, path_min, path_max)
        if solution
          return solution
        # else
        #   current_path.pop
        end
      end

      # puts "<--"
      return false
    end

    def solve
      a_min= (@min - 1)
      a_max=@max
      ideal_len = calc_ideal_range(a_min,a_max)
      main_configs = config(a_min, a_max, ideal_len)
      result = false

      # # last non-threaded-single-proc version:
      # # robot_long_performance.rb: 
      # # actually took 8.838757 seconds vs. expected 9.978728 seconds: 11.424011156532188% decrease.
      # puts "configs: #{all_size_configs.inspect}"
      # while ((! result) && all_size_configs.size > 0)
      #   # result = solve_recursive(current_path=[], row=0, col=0,*all_size_configs.shift)
      #   config_ary = all_size_configs.shift
      #   puts "trying config: #{config_ary.inspect}; #{all_size_configs.size} left"
      #   result = solve_recursive([], 0, 0, *config_ary)
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

# perhaps revert back to multi-process (guess best config-sizing):
# (randomly) choose another size (2/3 ?!) (going in reverse) for use w/ 2nd-thread

      ### BGN MULTIPROCESS      
      if main_configs.first == main_configs.last
        main_configs = [main_configs.first]
        # all_size_configs_reverse = all_size_configs.dup.reverse
        secondary_configs = main_configs.dup
      else
        # all_size_configs_reverse = all_size_configs[1..-1].dup.reverse
        secondary_configs = main_configs[1..-1].dup
      end
      proc_hash = {}
      pipes = {} # key1 => [rd, wr], key2 => ...
      
      puts "lg-configs: #{main_configs.inspect}"
      
      # how-to associate rd/wr pipes w/ the different procs?
      # how-to check each child-proc (and not confuse their pipes)
      
      # lg_rd, lg_wr = IO.pipe
      key = :lg_pid
      pipes[key] = IO.pipe
      proc_hash[key] = fork {
        pipes[key].first.close
        result = false
        while ((! result) && (main_configs.size > 0))
          config_ary = main_configs.shift
          puts "lg-trying config: #{config_ary.inspect}; #{main_configs.size} left"
          result = solve_recursive([], 0, 0,*config_ary)          
        end
        pipes[key].last.write result ? result : "false"
        pipes[key].last.close
        puts "thread large DONE"
      }
      pipes[key].last.close
      
      
      if main_configs.size > 1
        # new hack to force 2nd-thread/process to try an alternate "path"
        a_min = @min - 1
        a_max = @max
        puts "ideal via previous hack"
        ideal_lens = []
        ideal_lens << 2
        ideal_lens << 3
        ideal_lens << previous_three_or_two_to_the_n( diff(a_min,a_max) )
        ideal_len2 = ideal_len
        while ideal_len == ideal_len2
            ideal_len2 = ideal_lens.shift
        end
        puts "ideal: #{ideal_len2}"    
        secondary_configs = config( a_min, a_max, ideal_len2 )
        tmp = secondary_configs.shuffle
        secondary_configs = tmp
        # end new hack
      
        key = :sm_pid
        pipes[key] = IO.pipe
        # final_range_min, final_range_max = *main_configs[-1]
        # puts "final_range: #{final_range_min}:#{final_range_max}"
        # final_range_chunks = config(final_range_min, final_range_max,ideal_len)
        # 
        # puts "final_range_chunks: #{final_range_chunks.inspect}"
        # secondary_configs = secondary_configs[0..-2]
        # secondary_configs << final_range_chunks # [@max - 1, @max]
        puts "sm-configs: #{secondary_configs.inspect}"
      
        proc_hash[key] = fork {
          pipes[key].first.close
          result = false
          while ((! result) && (secondary_configs.size > 0))
            config_ary = secondary_configs.shift
            puts "sm-trying config: #{config_ary.inspect}; #{secondary_configs.size} left"
            result = solve_non_recursive([], 0, 0,*config_ary)         
      
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
      #           config_ary = all_size_configs_reverse.shift
      #           puts "lg-trying config: #{config_ary.inspect}; #{all_size_configs_reverse.size} left"
      #           Thread.current["result"] = solve_recursive([], 0, 0,*config_ary)          
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
      #             config_ary = all_size_configs.shift
      #             puts "sm-trying config: #{config_ary.inspect}; #{all_size_configs.size} left"
      #             Thread.current["result"] = solve_recursive([], 0, 0,*config_ary)
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
      puts "returning path: #{@path}\n"
      return result
    end

    # tweaked ideal_range for speed; (2, 4,) 8 is by far the fastest!
    # ? largest 2^n that is (strictly) < total_range (?!)
    # odd, some levels respond better to three_to_the_n
    # but it's not clear when to use which one...
    def previous_three_or_two_to_the_n( value )
      i = 1
      previous_two_n = two_n = 2
      
      begin
        previous_two_n = two_n
        i += 1
        two_n = 2 ** i
      end while two_n < value

      return previous_two_n if two_n == value
      
      i = 1
      previous_three_n = three_n = 3
      
      begin
        previous_three_n = three_n
        i += 1
        three_n = 3 ** i
      end while three_n < value
      
      return previous_three_n if three_n == value
        
      puts "hmm...: #{previous_two_n} v. #{previous_three_n}"
      
       # [ previous_three_n, previous_two_n][rand(2)]
     first_bomb_down(value, previous_three_n < previous_two_n ? previous_three_n : previous_two_n)
      # if even?(options[:level])
        # previous_three_n < previous_two_n ? previous_three_n : previous_two_n
      # else
        # previous_three_n > previous_two_n ? previous_three_n : previous_two_n
      # end
    end
    
    # i'm wondering if I need some formula like - sides of triangle:
    # board size (hypotenuse); min/max (and/or range); chunk-size

    # def even?(num)
    #   num % 2 == 0
    # end

    def first_bomb_down(total_range, previous_answer)
      return 1 if total_range < 2
      
      row = col = 0
      while map.avail?(row + 1,col)
        row += 1
      end

      return previous_answer if row >= total_range || row < 2
      row
    end

    def calc_ideal_range(a_min,a_max)
      total_range = diff(a_min,a_max)
      # ideal_range = (total_range / 2) + 2
      # 141 => 27 sec w/ ideal == 11; 6 => 3.6secs!
      
      # lvl 105 4 took longer than 2 (3 => 34.44sec is faster; 9 => 28.72sec)
      # lvl 141 ideal 16 => 52.010888 seconds; 6 => 3.5sec
      # lvl 142 ideal 16 => 357(ish) seconds; 9 => 327.488456; 8 => 193.461321; 4 => 25.313618; 2 => 8.154743
      
      ideal_range = map.width / total_range
      puts "divided #{ideal_range}-times evenly" if 0 == (map.width % total_range)
      fbd = first_bomb_down(total_range, ideal_range)
      ideal_range = (0 == (map.width % total_range)) ? ideal_range : fbd
      puts "ideal_range: #{ideal_range} (out of #{map.width})"
      
      ideal_range
    end

    def config(a_min=(@min - 1),a_max=@max, ideal_range=nil)
      ideal_range = calc_ideal_range(a_min,a_max) unless ideal_range
      total_range = diff(a_min,a_max)
      puts "min: #{a_min} - max: #{a_max}; total_range: #{total_range}"
      return [[a_min, a_max]] if total_range < 2 || ideal_range < 2 || total_range <= ideal_range

      ranges = []
      r_min = a_min
      r_max = r_min + ideal_range
      while ((r_max <= a_max) && (r_min < a_max))
        puts "adding: #{r_min}:#{r_max}"
        ranges << [r_min,r_max]
        r_min += ideal_range # + 1
        
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

    def diff(a_min=@min,a_max=@max)
      a_max - a_min
    end
    
    # # distance:
    # def mid(a_min=@min_size,a_max=@max)
    #   a_min + half(a_min, a_max)
    # end
    # 
    # # amount:
    # # an eighth:
    # def one_eighth(a_min=@min_size,a_max=@max)
    #   one_fourth(a_min, a_max) / 2
    # end
    # alias :one_bit :one_eighth
    # 
    # # require './lib/robot.rb'
    # # r = Robot.new
    # # r.min = 3
    # # r.min_size = 2
    # # r.max = 10
    # 
    # # amount
    # def half(a_min=@min_size,a_max=@max)
    #   diff(a_min, a_max) / 2
    # end
    # 
    # def one_fourth(a_min=@min_size,a_max=@max)
    #   half(a_min, a_max) / 2
    # end

    #
    # a string version of the current path-array
    #
    def path
      @path.join
    end

  end

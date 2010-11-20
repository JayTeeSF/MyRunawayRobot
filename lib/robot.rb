require './lib/array_extensions.rb'
require './lib/map.rb' # for 1.9.2
# require 'thread'  # For Mutex class in Ruby 1.8

class Robot
  attr_accessor :map, :path, :min, :max, :debug
# :jump_from, 
  #
  # this method gives the robots its marching orders
  # by default it will trigger the robot to "solve" the puzzle
  # (primarily because that's the API defined by runaway.rb)
  # options include:
  # :only_config  #<-- do not solve
  #
  def instruct(params={})
    puts "params: #{params.inspect}" if @debug
    options = { :board_x => 1, :board_y => 1, :ins_min => 0, :ins_max => 0 }.merge(params)

    @cache_off = options[:cache_off]
    @min = options[:ins_min]
    @max = options[:ins_max]

    @pre_min = @min - 1
    clear_path

    @map.config(options)
    @map.robot = self
    @map.draw_matrix(@map.matrix, 0, 0)

    # true by default
    @short_cut = options[:slow_cut] ? false : true

    # Should really be a mini-Matrix (should extract matrix from Map class)
    # @jump_from = []; @jump_from[0] = []
    if options[:ideal]
      @ideal_range = options[:ideal].to_i
    else
      ideal_range
    end
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

  def solve_recursive(current_path=[], row=0, col=0, path_min=@min,path_max=@max) #, jump_row=0, jump_col=0)
    solution = false
    #      puts "\n#{current_path.inspect}"
    path_size = current_path.size
    if path_size > path_min #@min_size
      # if @short_cut
      #   # store this if we're working on the _least_dense_/_min_ row
      #   @jump_from[row] ||= []; @jump_from[row][col] ||= []
      #   @jump_from[row][col] << current_path
      # end
      
      # puts "+"
      if path_size > (path_max - 1) # about to be too big ...check, and decide ...don't loop again
        if map.verify(current_path, row, col) #, jump_row, jump_col)
          puts "\tFound it (#{current_path.inspect})!\t"
          return current_path
        else
          # fill array as soon as we get a big-enough path
          return nil # return nil to indicate that we exited w/ a "potentially" valid row
          # problem ...the other returns, in this method need to propagate the 'nil' ...and not 'false'
        end
      else

        # result = map.verify(current_path, row, col)
        # return false if @short_cut && !result # nil
        if result = map.verify(current_path, row, col) #, jump_row, jump_col)
          puts "\tFound it (#{current_path.inspect})!\t"
          return current_path
        end
      end
    end


    move = Map.move(Robot.down(), row, col)
    if map.avail?(*move)
      # print direction == 1 ? "V" : ">"
      # puts "d-avail"
      r, c = *move

      sol_path = current_path.dup
      sol_path << Robot.down() #direction

      if solution = solve_recursive(sol_path, r, c, path_min, path_max) #, jump_row, jump_col)
        return solution
      end
    end

    move = Map.move(Robot.right(), row, col)
    if map.avail?(*move)
      # print other_direction == 1 ? "V" : ">"

      # puts "od-avail"
      r, c = *move

      sol_path = current_path.dup
      sol_path << Robot.right() #other_direction

      if solution = solve_recursive(sol_path, r, c, path_min, path_max) #, jump_row, jump_col)
        return solution
      end
    end
    # print other_direction == 1 ? "^" : "<"

    return solution
  end

  def solve
    # GC.disable

    time_of = {}
    time_of[:begin] = Time.now
    main_configs = config( @pre_min, @max)
    result = false

    # robot_long_performance.rb: 
    # actually took 5.229 seconds vs. expected 9.978728 seconds: 47.5985315964119% decrease.

    all_size_configs = main_configs.dup.reverse
    # .mid_first.reverse

    # @path = single_jump(time_of, result, all_size_configs)
    # @path = multi_p(time_of, result, all_size_configs)
    # @path = multi_t(time_of, result, all_size_configs)
    @path = single(time_of, result, all_size_configs)

    time_of[:end] = Time.now
    puts "returning path: #{@path}; took: #{time_of[:end] - time_of[:begin]}\n"
    return @path
  end

  def single_jump(time_of, result, all_size_configs)
    result = init_jump_points
    unless result
      puts "init'ted..."
      _height = Map.height(@jump_from)
      _width = Map.widest_point(@jump_from) 

puts "height: #{_height} / width: #{_width}; #{Time.now - time_of[:begin]}"
    end

    while ((! result) && all_size_configs.size > 0)
      config_ary = all_size_configs.shift
      puts "trying config: #{config_ary.inspect}; #{all_size_configs.size} left"

      (0).upto(_height) do |y_val|
        next if !@jump_from[y_val] || @jump_from[y_val].empty?
        # puts "found an across..."
        (0).upto(_width) do |x_val|
          next if !@jump_from[y_val][x_val] || @jump_from[y_val][x_val].empty?
          # puts "found an across/down..."
          
          
          # Attempt to jump_verify for the current (max-)range, starting from x_val, y_val
          min, max = *config_ary
          jump_row = x_val; jump_col = y_val
          result = solve_recursive([], x_val, y_val, min, max, jump_row, jump_col)  # it's got to "map.jump_verify..."  
          if result # Look for the first-portion of this result-path
            puts "looking for part-1 of: #{result.inspect}; #{Time.now - time_of[:begin]}"
            # Now, (regular) verify a combo-path made-up of the current result
            @jump_from[x_val][y_val].each do |start_path|
              if result = map.verify(start_path + result, 0, 0)      
                puts "full-path: #{result.inspect}"
                return result
              else
                puts "np"
              end
            end # each-path
          else
            puts "no jump-result; #{Time.now - time_of[:begin]}"
          end # jump-result

        end # width
      end # height

    end # while

    return result
  end

  # def boring_single(time_of, result, all_size_configs)
  def single(time_of, result, all_size_configs)
    result = nil
    while ((! result) && all_size_configs.size > 0)
      config_ary = all_size_configs.shift
      print "trying config: #{config_ary.inspect}; #{all_size_configs.size} left"
      result = solve_recursive([], 0, 0, *config_ary)
    end
    return result
  end

  def init_jump_points
    result = nil
    # initialize *new* jump_from: @jump_from[r][c] << path
    result = solve_recursive([], 0, 0, @pre_min, @min)
    @short_cut = false
    if @jump_from.empty?
      puts "empty jump_from"
      @jump_from[0][0] = [ []]
    end
    return result
  end

  def config(a_min=@pre_min,a_max=@max)
    puts "ideal_range: #{ideal_range} ( a_max(#{a_max}), a_min * 2(#{2 * a_min}) and a_max * 2(#{2 * a_max})) (out of #{map.width})"

    total_range = diff(a_min,a_max)
    puts "min: #{a_min} - max: #{a_max}; total_range: #{total_range}"
    return [[a_min, a_max]] if total_range < 2 || total_range <= ideal_range
    # || ideal_range < 2

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

  #
  # a string version of the current path-array
  #
  def path
    @path.join
  end

  def ideal_range(a_min=@pre_min,a_max=@max)
    @ideal_range ||= ideal_range_generator(a_min, a_max)
  end

  def ideal_range_generator(a_min, a_max)
    total_range = diff(a_min,a_max)
    # puts "\ntr: #{total_range}\n"
    return total_range if a_max < 10

    ideal = (total_range - 2) / 3
    return (ideal > 0) ? ideal : total_range
  end

  # # 1/4 => lvl105 (from 250ish): actually took 139.516 - 144 seconds.
  # # and even:
  # # returning path: RDRRDDDRRDDDDDRDDRRRRRDRRRRDRRD; took: 38.09
  # #   interesting, this trick only speeds-up the _final_ chunk
  # #   multi_t: actually took 111.13 seconds.
  # # 1/3 => actually took 157.138 seconds.
  # # switch d/r (see if it matters for _some_ levels)
  # #
  # def pick_directions
  #   # 1 == rand(4) ? [Robot.down(), Robot.right()] : [Robot.right(), Robot.down()]
  #   [Robot.down(), Robot.right()]
  # end

  # def fancy_single(time_of, result, all_size_configs)
  #   all_size_configs = all_size_configs.reverse
  #   # shuffle!
  #   time_of[:prep_end] = Time.now
  #   i = 0
  #   # short_cut = @short_cut
  #   @start_from = []
  #   # @cant_go = [] # << [r, c, direction]
  # 
  #   # got it: fold the map, based-on 0..min
  #   # only the cells that "show-through" are "valid"
  #   # then run this initial loop, in order to generate @start_from!
  #   if @short_cut
  #     # short_cut = true
  #     # short_cut = false
  #     # initialize @start_from
  #     result = solve_recursive([], 0, 0, @pre_min, @min)
  #     # @short_cut = false # why?!
  #     # fold_key_pts
  #   end
  #   @start_from = [ [[], 0, 0] ] if @start_from.empty?
  #   # trim_starts_and_create_restrictions if short_cut
  # 
  #   # mid_starts = @start_from.mid_first[0..-3]
  #   # end_starts = [@start_from[0], @start_from[-1]].uniq
  #   # current_starts = @start_from.mid_first.uniq.dup
  #   a = all_size_configs.dup
  # 
  #   # [mid_starts.mid_first, end_starts].each do |starts|
  #   # current_starts.each do |starts|
  #   # puts "starts-count: #{starts.inspect}"
  #   all_size_configs = a
  #   while ((! result) && all_size_configs.size > 0)
  #     time_of[:"loop_#{i}_begin"] = Time.now
  #     config_ary = all_size_configs.shift
  #     print "trying config: #{config_ary.inspect}; #{all_size_configs.size} left"
  # 
  #     # find a way to trim @start_from!
  #     # can I detect when solve_recursive returns an invalid-path:
  #     # e.g. it drops-out the back-door, as opposed to growing beyond max (i.e. config_ary[1] )
  #     # no...
  # 
  #     start_arys =  @start_from.mid_first.uniq.dup
  #     @start_from = []
  #     start_arys.each do |start_ary|
  #       # puts "start_ary: #{start_ary.inspect}; #{start_ary[1]}"
  #       break if result = solve_recursive(start_ary[0], start_ary[1], start_ary[2], *config_ary)
  #     end
  # 
  #     unless result
  #       unless @short_cut
  #         @start_from = start_arys
  #         # #     # @short_cut = short_cut # possibly re-try
  #       else
  #         @start_from = [ [[], 0, 0] ] if @start_from.empty?
  #         # #     @cant_go = [] # << [r, c, direction]
  #         # #     trim_starts_and_create_restrictions
  #       end
  #     end
  # 
  #     time_of[:"loop_#{i}_end"] = Time.now
  #     puts "; took: #{time_of[:"loop_#{i}_end"] - time_of[:"loop_#{i}_begin"]}\n"
  # 
  #     i += 1
  #   end # end while
  #   # break if result
  #   # end # - each do
  #   result
  # end

  def multi_t(time_of, result, all_size_configs)
    ### BGN THREADED
    # all_size_configs_reverse = all_size_configs[1..-1].dup.reverse
    #large_configs = all_size_configs.dup.mid_first.uniq
    #small_configs = all_size_configs[0..-2].dup
    small_configs = [all_size_configs[0].dup, all_size_configs[-1].dup].uniq
    large_configs = all_size_configs[1..-2].dup.mid_first.uniq
    # [0..-2]

    thread_ary = []
    puts "lg-configs: #{large_configs.inspect}"

    thread_ary[thread_ary.size] = Thread.new do
      Thread.current["result"] = false
      i = 0
      while ((! Thread.current["result"]) && (large_configs.size > 0))
        time_of[:"loop_#{i}_begin"] = Time.now
        config_ary = large_configs.shift
        print "lg-trying config: #{config_ary.inspect}; #{large_configs.size} left"
        Thread.current["result"] = solve_recursive([], 0, 0,*config_ary)
        time_of[:"loop_#{i}_end"] = Time.now
        puts "; took: #{time_of[:"loop_#{i}_end"] - time_of[:"loop_#{i}_begin"]}\n"
        i += 1
      end
      puts "thread large DONE"
    end

    if small_configs.size >= 1
      # all_size_configs = all_size_configs[0..-2]
      puts "sm-configs: #{small_configs.inspect}"

      thread_ary[thread_ary.size] = Thread.new do
        Thread.current["result"] = false
        i = 0
        while ((! Thread.current["result"]) && (small_configs.size > 0))
          time_of[:"loop_#{i}_begin"] = Time.now
          config_ary = small_configs.shift
          print "sm-trying config: #{config_ary.inspect}; #{small_configs.size} left"
          Thread.current["result"] = solve_recursive([], 0, 0,*config_ary)
          time_of[:"loop_#{i}_end"] = Time.now
          puts "; took: #{time_of[:"loop_#{i}_end"] - time_of[:"loop_#{i}_begin"]}\n"
          i += 1
        end
        puts "thread small DONE"
      end
    end

    # if we run out of threads || we get a result STOP
    thread_ary_size = thread_ary.size
    deleted_threads = []
    until thread_ary_size <= 0 || result
      sleep 0.005  # actually took 160.79 seconds. ...but I may be sleeping in wrong place!
      # w sleep 0.001 => 157s <-- but load exceeds 2.0!
      # w/o sleep 247s
      thread_ary.each_with_index do |thr,i|
        next if deleted_threads.include?(i)

        if ! thr.status
          # puts "thread_ary.size was: #{thread_ary.size} vs. #{thread_ary_size}"
          # thread_ary.delete(i) # BAD modifying loop-xxx... doesn't work
          unless deleted_threads.include?(i)
            thread_ary_size -= 1
            deleted_threads << i
            puts "deleted thread: #{i}"            
          end

          if thr && thr["result"]
            #got what we wanted
            result = thr["result"]
          end # if got result

          # puts "calling break..."
          break
          # puts "never here?!"
        end # if thread done
        # puts "end of for-loop"
      end # loop through threads
      # puts "end of while-loop"
    end # while

    #kill all other threads
    thread_ary.each {|thr| thr.kill }
    ### END THREADED
    result
  end

  def multi_p(time_of, result, all_size_configs)
    ### BGN MULTIPROCESS      
    large_configs = all_size_configs.dup.reverse
    small_configs = all_size_configs[0..-2].dup

    proc_hash = {}
    pipes = {} # key1 => [rd, wr], key2 => ...

    puts "all-configs: #{all_size_configs.inspect}"

    # lg_rd, lg_wr = IO.pipe
    key = :lg_pid 
    pipes[key] = IO.pipe
    proc_hash[key] = fork {
      pipes[key].first.close

      if result = single(time_of, result, large_configs)
        pipes[key].last.write result 
      else
        pipes[key].last.write "false"
      end
      pipes[key].last.close
      puts "thread large DONE"
    }
    pipes[key].last.close


    if small_configs.size >= 1

      key = :sm_pid
      pipes[key] = IO.pipe
      puts "sm-configs: #{small_configs.inspect}"

      proc_hash[key] = fork {
        pipes[key].first.close
        if result = single(time_of, result, small_configs)
          pipes[key].last.write result 
        else
          pipes[key].last.write "false"
        end

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
    result
  end

end

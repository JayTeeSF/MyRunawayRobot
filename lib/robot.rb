require './lib/map.rb' # for 1.9.2
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
      @map.draw_matrix(@start_x, @start_y)
      solve() if options[:only_config].nil?
    end

    def initialize(params={})
      @map = Map.new params
      @debug = params[:debug]
      params.delete(:debug)
      # movin_forward = true
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

    def solve_recursive(current_path=[], row=0, col=0, path_min=@min,path_max=@max)
      #      puts "\n#{current_path.inspect}"
      path_size = current_path.size
      if path_size > path_min #@min_size
        if path_size > path_max # @max
          return false
        elsif map.verify(current_path, row, col)
          puts "\tFound it (#{current_path.inspect})!\t"
          return current_path
        end
      end


      #      puts "d: r*#{row}/c#{col}"
      # if valid_try = try(Robot.down(), row, col, current_path)
      #   valid_try << path_min
      #   valid_try << path_max
      #   if solution = solve_recursive(*valid_try)
      #     return solution
      #   end
      # end

      move = Map.move(Robot.down(), row, col)
      if map.avail?(*move)
        # puts "r-avail"
        r, c = *move
        sol_path = current_path.dup
        sol_path << Robot.down()

        if solution = solve_recursive(sol_path, r, c, path_min, path_max)
          return solution
        end
      end

      #      puts "r: r#{row}/c*#{col}"
      # if valid_try = try(Robot.right(), row, col, current_path)
      #   valid_try << path_min
      #   valid_try << path_max
      #   if solution = solve_recursive(*valid_try)
      #     return solution
      #   end
      # end

      move = Map.move(Robot.right(), row, col)
      if map.avail?(*move)
        # puts "r-avail"
        r, c = *move
        sol_path = current_path.dup
        sol_path << Robot.right()

        if solution = solve_recursive(sol_path, r, c, path_min, path_max)
          return solution
        end
      end

      #      puts "<--"
      return false
    end

    # def try(direction, row, col, current_path)
    #   move = Map.move(direction, row, col)      
    #   if map.avail?(*move)
    #     # puts "#{direction}-avail"
    #     r, c = *move
    #     sol_path = current_path.dup
    #     sol_path << direction
    #     [sol_path, r, c]
    #   end
    # end

    def solve
      # GC.disable

      time_of = {}
      time_of[:begin] = Time.now
      a_min= (@min - 1)
      a_max=@max
      main_configs = config( a_min, a_max, 1 + calc_ideal_range(a_min, a_max) )
      result = false
      all_size_configs = main_configs

      #      # # last non-threaded-single-proc version:
      #      # # robot_long_performance.rb: 
      #      # # actually took 8.838757 seconds vs. expected 9.978728 seconds: 11.424011156532188% decrease.
      #      # puts "configs: #{all_size_configs.inspect}"
      result = multi_t(time_of, result, all_size_configs)

      # MULTI goes here...

      @path = result
      time_of[:end] = Time.now
      puts "returning path: #{@path}; took: #{time_of[:end] - time_of[:begin]}\n"
      return result
    end

    def regular(time_of, result, all_size_configs)
      time_of[:prep_end] = Time.now
      i = 0
      while ((! result) && all_size_configs.size > 0)
        time_of[:"loop_#{i}_begin"] = Time.now
        config_ary = all_size_configs.shift
        print "trying config: #{config_ary.inspect}; #{all_size_configs.size} left"
        result = solve_recursive([], 0, 0, *config_ary)
        # result = solve_non_recursive([], 0, 0, *config_ary)
        time_of[:"loop_#{i}_end"] = Time.now
        puts "; took: #{time_of[:"loop_#{i}_end"] - time_of[:"loop_#{i}_begin"]}\n"
        i += 1
      end
      result
    end

    def multi_t(time_of, result, all_size_configs)
      ### BGN THREADED
      # all_size_configs_reverse = all_size_configs[1..-1].dup.reverse
      large_configs = all_size_configs.dup.reverse
      small_configs = all_size_configs[0..-2].dup
      
      thread_ary = []
      puts "lg-configs: #{large_configs.inspect}"

      thread_ary[thread_ary.size] = Thread.new do
        Thread.current["result"] = false
        while ((! Thread.current["result"]) && (large_configs.size > 0))
          config_ary = large_configs.shift
          puts "lg-trying config: #{config_ary.inspect}; #{large_configs.size} left"
          Thread.current["result"] = solve_recursive([], 0, 0,*config_ary)          
        end
        puts "thread large DONE"
      end

      if small_configs.size >= 1
        # all_size_configs = all_size_configs[0..-2]
        puts "sm-configs: #{small_configs.inspect}"

        thread_ary[thread_ary.size] = Thread.new do
          Thread.current["result"] = false
          while ((! Thread.current["result"]) && (small_configs.size > 0))
            config_ary = small_configs.shift
            puts "sm-trying config: #{config_ary.inspect}; #{small_configs.size} left"
            Thread.current["result"] = solve_recursive([], 0, 0,*config_ary)
          end
          puts "thread small DONE"
        end
      end

      # if we run out of threads || we get a result STOP
      thread_ary_size = thread_ary.size
      deleted_threads = []
      until thread_ary_size <= 0 || result
        sleep 0.01  # is this too long/short ?!
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
      # if main_configs.first == main_configs.last
      #   main_configs = [main_configs.first]
      #   # all_size_configs_reverse = all_size_configs.dup.reverse
      #   secondary_configs = main_configs.dup
      # else
      #   # all_size_configs_reverse = all_size_configs[1..-1].dup.reverse
      #   secondary_configs = main_configs[1..-1].dup
      # end
      large_configs = all_size_configs.dup.reverse
      small_configs = all_size_configs[0..-2].dup

      proc_hash = {}
      pipes = {} # key1 => [rd, wr], key2 => ...

      puts "all-configs: #{all_size_configs.inspect}"

      # how-to associate rd/wr pipes w/ the different procs?
      # how-to check each child-proc (and not confuse their pipes)

      # lg_rd, lg_wr = IO.pipe
      key = :lg_pid 
      pipes[key] = IO.pipe
      proc_hash[key] = fork {
        pipes[key].first.close
        # result = false
        # while ((! result) && (main_configs.size > 0))
        #   config_ary = main_configs.shift
        #   puts "lg-trying config: #{config_ary.inspect}; #{main_configs.size} left"
        #   result = solve_recursive([], 0, 0,*config_ary)          
        # end

        if result = regular(time_of, result, large_configs)
          pipes[key].last.write result 
        else
          pipes[key].last.write "false"
        end
        pipes[key].last.close
        puts "thread large DONE"
      }
      pipes[key].last.close


      if small_configs.size >= 1
        # # new hack to force 2nd-thread/process to try an alternate "path"
        # a_min = @min - 1
        # a_max = @max
        # puts "ideal via previous hack"
        # ideal_lens = []
        # ideal_lens << 2
        # ideal_lens << 3
        # ideal_lens << previous_three_or_two_to_the_n( diff(a_min,a_max) )
        # ideal_len2 = ideal_len
        # while ideal_len == ideal_len2
        #     ideal_len2 = ideal_lens.shift
        # end
        # puts "ideal: #{ideal_len2}"    
        # secondary_configs = config( a_min, a_max, ideal_len2 )
        # tmp = secondary_configs.shuffle
        # secondary_configs = tmp
        # # end new hack

        key = :sm_pid
        pipes[key] = IO.pipe
        # final_range_min, final_range_max = *main_configs[-1]
        # puts "final_range: #{final_range_min}:#{final_range_max}"
        # final_range_chunks = config(final_range_min, final_range_max,ideal_len)
        # 
        # puts "final_range_chunks: #{final_range_chunks.inspect}"
        # secondary_configs = secondary_configs[0..-2]
        # secondary_configs << final_range_chunks # [@max - 1, @max]
        puts "sm-configs: #{small_configs.inspect}"

        proc_hash[key] = fork {
          pipes[key].first.close
          # result = false
          # while ((! result) && (secondary_configs.size > 0))
          #   config_ary = secondary_configs.shift
          #   puts "sm-trying config: #{config_ary.inspect}; #{secondary_configs.size} left"
          #   result = solve_non_recursive([], 0, 0,*config_ary)         
          #            
          # end
          # pipes[key].last.write result ? result : "false"

          if result = regular(time_of, result, small_configs)
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

    #
    # a string version of the current path-array
    #
    def path
      @path.join
    end

    # i'm wondering if I need some formula like - sides of triangle:
    # board size (hypotenuse); min/max (and/or range); chunk-size

    def calc_ideal_range(a_min,a_max)
      total_range = diff(a_min,a_max)
      # return total_range # added to avoid breaking-up chunk -- not working for some maps!
      ideal_range = (total_range / 2) + 2
      # 141 => 27 sec w/ ideal == 11; 6 => 3.6secs!

      # lvl 105 4 took longer than 2 (3 => 34.44sec is faster; 9 => 28.72sec)
      # lvl 141 ideal 16 => 52.010888 seconds; 6 => 3.5sec
      # lvl 142 ideal 16 => 357(ish) seconds; 9 => 327.488456; 8 => 193.461321; 4 => 25.313618; 2 => 8.154743
      # why 9 ?!?
      # starting level 104...
      # ideal_range: 3 (out of 54)
      # min: 18 - max: 32; total_range: 14
      # adding: 18:22
      # adding: 22:26
      # adding: 26:30
      # adding: 30:32
      # returning path: RRDDDRDDDRDRDRRRDDDRRRDDRDR
      # actually took 142.526393 seconds.
      #
      #starting level 105...
      #ideal_range: 3 (out of 54)
      #min: 18 - max: 32; total_range: 14
      #adding: 18:22
      #adding: 22:26
      #adding: 26:30
      #adding: 30:32
      #returning path: RDRRDDDRRDDDDDRDDRRRRRDRRRRDRRD
      #actually took 281.720983 seconds.
      #

      ideal_range = if total_range / 9 >= 3
        9
      elsif total_range / 6 >= 3
        6
      elsif total_range / 3 >= 3
        3
      else
        2
      end
      # map.width / total_range



      puts "divided #{ideal_range}-times evenly" if 0 == (map.width % total_range)
      #fbd = first_bomb_down(total_range, ideal_range)
      #ideal_range = (0 == (map.width % total_range)) ? ideal_range : fbd
      puts "ideal_range: #{ideal_range} (out of #{map.width})"

      ideal_range
    end
  end

__END__

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



require './lib/array_extensions.rb'
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

      @pre_min = @min - 1
      clear_path

      @map.config(options)
      @map.robot = self
      @map.draw_matrix(@map.matrix,@start_x, @start_y)

      # true by default
      @short_cut = options[:slow_cut] ? false : true

      if options[:ideal]
        @ideal_range = options[:ideal].to_i
      else
        ideal_range
        @ideal_range
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

    #
    # 1/4 => lvl105 (from 250ish): actually took 139.516 - 144 seconds.
    # and even:
    # returning path: RDRRDDDRRDDDDDRDDRRRRRDRRRRDRRD; took: 38.09
    #   interesting, this trick only speeds-up the _final_ chunk
    #   multi_t: actually took 111.13 seconds.
    # 1/3 => actually took 157.138 seconds.
    # switch d/r (see if it matters for _some_ levels)
    #
    def pick_directions
      # 1 == rand(4) ? [Robot.down(), Robot.right()] : [Robot.right(), Robot.down()]
      [Robot.down(), Robot.right()]
    end

    def solve_recursive(current_path=[], row=0, col=0, path_min=@min,path_max=@max)
      # row = row.to_i; col = col.to_i
      # if row.class != Fixnum
      #   puts "BOOOM: row is: #{row.inspect}"
      # end
      solution = false
      #      puts "\n#{current_path.inspect}"
      path_size = current_path.size
      if path_size > path_min #@min_size
        # puts "+"
        if path_size > (path_max - 1)
          if map.verify(current_path, row, col)
            puts "\tFound it (#{current_path.inspect})!\t"
            return current_path
          else
            # if @short_cut
            #   #   # store this if we're working on the _least_dense_/_min_ row
            #   @start_from << [current_path, row, col]
            #   # puts ','
            #   if @start_from.size > 248460
            #     #     puts "memory blow-ou"
            #     puts "M"
            #     @short_cut = false
            #     @start_from = []
            #   end
            # end

            return nil # return nil to indicate that we exited w/ a "potentially" valid row
            # problem ...the other returns, in this method need to propagate the 'nil' ...and not 'false'
          end
        else

          # result = map.verify(current_path, row, col)
          # return false if @short_cut && !result # nil
          if result = map.verify(current_path, row, col)
            puts "\tFound it (#{current_path.inspect})!\t"
            return current_path
          end
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

      # unless @cant_go.include?([row,col, Robot.down])

      # other_direction, direction = pick_directions # would like to calculate these ahead-of time
      # move = [row + 1, col] #
      move = Map.move(Robot.down(), row, col)
      if map.avail?(*move)
        # print direction == 1 ? "V" : ">"
        # puts "d-avail"
        r, c = *move
        # if r.class != Fixnum
        #   puts "BOOOM-DOWN: row is: #{r.inspect}/#{r.class}"
        # end
          
        sol_path = current_path.dup
        sol_path << Robot.down() #direction

        if solution = solve_recursive(sol_path, r, c, path_min, path_max)
          return solution
        end
      end
      # end
      # print direction == 1 ? "^" : "<"

      #      puts "r: r#{row}/c*#{col}"
      # if valid_try = try(Robot.right(), row, col, current_path)
      #   valid_try << path_min
      #   valid_try << path_max
      #   if solution = solve_recursive(*valid_try)
      #     return solution
      #   end
      # end

      # unless @cant_go.include?([row,col, Robot.right])

      # move = [row, col+1] # Map.move(other_direction, row, col)
      move =Map.move(Robot.right(), row, col)
      if map.avail?(*move)
        # print other_direction == 1 ? "V" : ">"

        # puts "od-avail"
        r, c = *move
        # if r.class != Fixnum
        #   puts "BOOOM-RIGHT: row is: #{r.inspect}/#{r.class}"
        # end
        
        sol_path = current_path.dup
        sol_path << Robot.right() #other_direction

        if solution = solve_recursive(sol_path, r, c, path_min, path_max)
          return solution
        end
      end
      # end
      # print other_direction == 1 ? "^" : "<"

      return solution  # undo... don't want to re-verify
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
      main_configs = config( @min - 1, @max)
      result = false

      # robot_long_performance.rb: 
      # actually took 8.838757 seconds vs. expected 9.978728 seconds: 11.424011156532188% decrease.
      # w/ random (weighted) right/down
      # actually took 5.229 seconds vs. expected 9.978728 seconds: 47.5985315964119% decrease.

      # result = multi_p(time_of, result, all_size_configs)

      all_size_configs = main_configs.dup
       #result = multi_t(time_of, result, all_size_configs)
      # this just in... add code to fold, the folded matricies even further (if they're over a certain size (18 ?!))
      result = single(time_of, result, all_size_configs)

      @path = result
      time_of[:end] = Time.now
      puts "returning path: #{@path}; took: #{time_of[:end] - time_of[:begin]}\n"
      return result
    end

    # def trim_starts_and_create_restrictions
    def fold_key_pts
      puts "num starts: #{@start_from.size}"
      # need to cull this list!
      # from each of these points, let's consider the constraints of the 1st move:
      # if I go down 1-move, then how-many more down's must I go, til I can turn right?
      # elsif I turn right 1-move, then how-many more right's must I go, til I can go down?
      # if I can't do _either_ of those two things, from the current row/col ...
      # then delete all entries from start_from that have that same constraint

      # remove_from_start = []
      r_c = []
      @start_from.each do |start_ary|
        # I _probably_ can't trim any start_from's
        # however, I can avoid checking solutions that continue in a certain direction...
        #@cant_go = [r,c, Robot.down]
        # cant_go_count = 0
        next if r_c.include?([start_ary[1], start_ary[2]])
        map.fold_map(start_ary[1],start_ary[2])
        map.draw_matrix(map.map_folds["#{start_ary[1]}_#{start_ary[2]}"], start_ary[1], start_ary[2])


        # cant_go_down = ! bomb_down_options.any? do |path|
        #   map.satisfy?(path,start_ary[1], start_ary[2])
        # end
        # 
        # cant_go_right = ! bomb_right_options.any? do |path|
        #   map.satisfy?(path,start_ary[1], start_ary[2])
        # end
        # 
        # if cant_go_down
        #   @cant_go << [start_ary[1], start_ary[2], Robot.down]
        # elsif cant_go_right
        #   @cant_go << [start_ary[1], start_ary[2], Robot.right]
        # elsif cant_go_right && cant_go_down
        #   # may not need this; should probably start from 0, everytime!
        #   remove_from_start << [ start_ary[1], start_ary[2] ]
        # end

        r_c << [start_ary[1], start_ary[2]]
      end
      # @cant_go.uniq!
      # puts "unique coords: #{r_c.inspect}; coords to remove: #{remove_from_start.inspect} restrictions: #{@cant_go.inspect}"

      # # cleanup
      # @start_from.reject!{ |e| remove_from_start.include?([e[1], e[2]]) }
      # puts "num starts, now: #{@start_from.size}"
    end

    # first_bomb_down
    # going X from a cell is not valid, if one can't turn prior to going first_bomb_X moves
    def bomb_down_options
      @bdos ||= begin
        bdos = []
        bdo = []
        (1).upto(map.first_bomb_down - 1) do |i|
          i.times { bdo << Robot.down }
          bdo << Robot.right
          bdos << bdo
        end

        bdos
      end
    end

    def bomb_right_options
      @bros ||= begin
        bros = []
        bro = []
        (1).upto(map.first_bomb_right - 1) do |i|
          i.times { bro << Robot.right }
          bro << Robot.down
          bros << bro
        end

        bros
      end
    end

    # def rtd_path
    #   @rtd_path ||= begin
    #     rtd = map.num_right_from_start
    #     _rtd_path = []
    #     rtd.times { _rtd_path << Robot.right }
    #     _rtd_path << Robot.down
    #   end
    # end
    # 
    # def dtr_path
    #   @dtr_path ||= begin
    #     dtr = map.num_down_from_start
    #     _dtr_path = []
    #     dtr.times { _dtr_path << Robot.down }
    #     _dtr_path << Robot.right
    #   end
    # end

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

    def fancy_single(time_of, result, all_size_configs)
      all_size_configs = all_size_configs.reverse
      # shuffle!
      time_of[:prep_end] = Time.now
      i = 0
      # short_cut = @short_cut
      @start_from = []
      # @cant_go = [] # << [r, c, direction]

      # got it: fold the map, based-on 0..min
      # only the cells that "show-through" are "valid"
      # then run this initial loop, in order to generate @start_from!
      if @short_cut
        # short_cut = true
        # short_cut = false
        # initialize @start_from
        result = solve_recursive([], 0, 0, @min - 1, @min)
        # @short_cut = false # why?!
        # fold_key_pts
      end
      @start_from = [ [[], 0, 0] ] if @start_from.empty?
      # trim_starts_and_create_restrictions if short_cut

      # mid_starts = @start_from.mid_first[0..-3]
      # end_starts = [@start_from[0], @start_from[-1]].uniq
      # current_starts = @start_from.mid_first.uniq.dup
      a = all_size_configs.dup

      # [mid_starts.mid_first, end_starts].each do |starts|
      # current_starts.each do |starts|
        # puts "starts-count: #{starts.inspect}"
        all_size_configs = a
        while ((! result) && all_size_configs.size > 0)
          time_of[:"loop_#{i}_begin"] = Time.now
          config_ary = all_size_configs.shift
          print "trying config: #{config_ary.inspect}; #{all_size_configs.size} left"

          # find a way to trim @start_from!
          # can I detect when solve_recursive returns an invalid-path:
          # e.g. it drops-out the back-door, as opposed to growing beyond max (i.e. config_ary[1] )
          # no...

          start_arys =  @start_from.mid_first.uniq.dup
          @start_from = []
         start_arys.each do |start_ary|
            # puts "start_ary: #{start_ary.inspect}; #{start_ary[1]}"
            break if result = solve_recursive(start_ary[0], start_ary[1], start_ary[2], *config_ary)
          end

          unless result
            unless @short_cut
              @start_from = start_arys
          # #     # @short_cut = short_cut # possibly re-try
            else
              @start_from = [ [[], 0, 0] ] if @start_from.empty?
          # #     @cant_go = [] # << [r, c, direction]
          # #     trim_starts_and_create_restrictions
            end
          end

          time_of[:"loop_#{i}_end"] = Time.now
          puts "; took: #{time_of[:"loop_#{i}_end"] - time_of[:"loop_#{i}_begin"]}\n"

          i += 1
        end # end while
        # break if result
      # end # - each do
      result
    end

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

    def config(a_min=(@min - 1),a_max=@max)
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

    # i'm wondering if I need some formula like - sides of triangle:
    # board size (hypotenuse); min/max (and/or range); chunk-size

    def ideal_range(a_min=@pre_min,a_max=@max)
      @ideal_range ||= begin
        total_range = diff(a_min,a_max)
        # return total_range # added to avoid breaking-up chunk -- not working for some maps!
        ideal = (total_range / 2) + 2
        # 141 => 27 sec w/ ideal == 11; 6 => 3.6secs!
        # lvl 105 4 took longer than 2 (3 => 34.44sec is faster; 9 => 28.72sec)
        # lvl 141 ideal 16 => 52.010888 seconds; 6 => 3.5sec
        # lvl 142 ideal 16 => 357(ish) seconds; 9 => 327.488456; 8 => 193.461321; 4 => 25.313618; 2 => 8.154743
        # starting level 104...
        # ideal: 3 (out of 54)
        # min: 18 - max: 32; total_range: 14
        # adding: 18:22
        # adding: 22:26
        # adding: 26:30
        # adding: 30:32
        # returning path: RRDDDRDDDRDRDRRRDDDRRRDDRDR
        # actually took 142.526393 seconds.
        #
        #starting level 105...
        #ideal: 3 (out of 54)
        #min: 18 - max: 32; total_range: 14
        #adding: 18:22
        #adding: 22:26
        #adding: 26:30
        #adding: 30:32
        #returning path: RDRRDDDRRDDDDDRDDRRRRRDRRRRDRRD
        #actually took 281.720983 seconds.
        #

        ideal = if total_range / 9 >= 3
          9
        elsif total_range / 6 >= 3
          6
        elsif total_range / 3 >= 3
          3
        else
          2
        end
        # map.width / total_range
        puts "divided #{ideal}-times evenly" if 0 == (map.width % total_range)

        double_min = 2 * a_min
        puts "double_min: #{double_min}; max: #{a_max}"

        if double_min > a_max
          puts "ok"
          res = 2 + (double_min - a_max)
          res += 1 # I dunno
          res += 1 # I really don't know
          # res / 2 # too big
        else
          puts "nok"
          ideal
        end
        # puts "#{[map.num_down_from_start, map.num_right_from_start].inspect}"
        # [map.num_down_from_start, map.num_right_from_start].max
        # 3
        # from any given point, what's the next point w/ the ?fewest? # of braches
      end
    end
  end

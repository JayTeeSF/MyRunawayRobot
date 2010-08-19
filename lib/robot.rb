require 'rubygems'
require 'thread'  # For Mutex class in Ruby 1.8
require 'drb'
require 'lib/ssh'

class Robot

  attr_accessor :map, :path, :min, :max, :start_x, :start_y, :debug, :matrix,
  :right_till_bomb, :down_till_bomb, :instruct_options, :servers

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
    @instruct_options = options

    @servers = [
    {'nokill' => 1, 'dir' => '/Users/jthomas/Projects/MyRunawayRobot/src/lib', 'u' => 'jthomas', 'ip' => '192.168.1.127', 'ruby' => '/Users/jthomas/.rvm/rubies/ree-1.8.7-2010.01/bin/ruby', 'port' => '61676'},
    {'nokill' => 1, 'dir' => '/Users/jthomas/Projects/MyRunawayRobot/src/lib', 'u' => 'jthomas', 'ip' => '192.168.1.127', 'ruby' => '/Users/jthomas/.rvm/rubies/ree-1.8.7-2010.01/bin/ruby', 'port' => '61679'}
    ]
    #{'nokill' => 1, 'dir' => '/Users/jlthomas/Desktop', 'u' => 'jlthomas', 'ip' => '192.168.1.122', 'ruby' => '/usr/local/bin/ruby', 'port' => '61676'},
    #{'nokill' => 1, 'dir' => '/Users/jlthomas/Desktop', 'u' => 'jlthomas', 'ip' => '192.168.1.7', 'ruby' => '/Users/jlthomas/.rvm/rubies/ruby-1.9.1-p378/bin/ruby', 'port' => '61676'}, {'nokill' => 1, 'dir' => '/Users/jlthomas/Desktop', 'u' => 'jlthomas', 'ip' => '192.168.1.7', 'ruby' => '/Users/jlthomas/.rvm/rubies/ruby-1.9.1-p378/bin/ruby', 'port' => '61677'},

    @start_x = 0
    @start_y = 0
    @cache_off = options[:cache_off]
    @min = options[:ins_min]
    @max = options[:ins_max]
    @diff = @max - @min
	@map_terrain = options[:terrain_string]
	@map_width = options[:board_x] - 1
	@map_height = options[:board_x] - 1
    clear_path
    @right_till_bomb = 0
    @down_till_bomb = 0

    construct_matrix
    solve() if options[:only_config].nil?
  end

  def self.prompt(msg="what?",options={})
    print msg + " "
    system "stty -echo" if options[:pwd]
    result = gets.chomp
    system "stty echo" if options[:pwd]
    puts ""
    return result
  end

  def initialize(params={})
    @awaiting = {}
    @doubled = {}
    @pwd = params[:pwd] || Robot.prompt("what's the pwd?",:pwd => true)
    @debug = params[:debug]
    @lock = Mutex.new  # For thread safety
    params.delete(:debug)
    instruct(params) if params != {}
  end

  def clear_matrix
    @matrix = []
  end

  def get_doubled(val)
    #while true
    #@lock.synchronize {
      return @doubled[val]
    #}
    #sleep rand
    #end
  end

  def undoubled
    #while true
    #@lock.synchronize {
     puts "preparing to sort and each..."
     #@awaiting.keys.sort.reverse.each do |wait_num|  
     @awaiting.keys.sort_by {rand}.each do |wait_num|  
      puts "awaiting key: #{wait_num}"
      next if wait_num >= (@max - 2)
      if get_doubled(wait_num).nil?
        return wait_num
      end
     end
     return nil
    #}
    #sleep rand
    #end
  end

  def add_awaiting(val)
    #while true
    #@lock.synchronize {
      @awaiting[val] = 1
      return true
    #}
    #sleep rand
    #end
  end

  def remove_awaiting(val)
    #while true
    #@lock.synchronize {
      @awaiting.delete(val)
      puts "removing val: #{val}"
      return true
    #}
    #sleep rand
    #end
  end

  def awaiting
    #while true
    #@lock.synchronize {
      return @awaiting
    #}
    #sleep rand
    #end
  end
  # human readable
  def draw_matrix(row=nil,col=nil)
    @lock.synchronize {
    #return unless @debug
    puts "called with row(#{row.inspect}), col(#{col.inspect})"
    construct_matrix unless @matrix
    if (row && col)
      # deep copy the array, before inserting our robot
      matrix = Marshal.load(Marshal.dump(@matrix))
      matrix[row][col] = (matrix[row][col] == Robot.bomb()) ? Robot.boom() : Robot.robot
    else
      matrix = @matrix
    end

    puts "\n#-->"
    matrix.each {|current_row| puts "#{current_row}"}
    puts "#<--\n"
    }
  end

  def construct_matrix
    next_cell = cell_generator
    clear_matrix
    (0..@map_height).each do |y_val|
      matrix_row = []
      (0 .. @map_width).each do |x_val|
        result = ('.' == next_cell.call ? Robot.safe : Robot.bomb )
        matrix_row << result
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
    terrain_ary = @map_terrain.gsub(/[^X\.]+/,"").split(//)
    i = -1
    lambda { i += 1; terrain_ary[i] }
  end

  # should make this work from a given coordinate...
  def moves_till_bomb(direction)
  	count = 0
  	if direction == 'right'
      # /^([\.]+)X/.match(@map_terrain)
      tmp_path = @map_terrain[/^([\.]+)X/,1]
      if tmp_path
        count += tmp_path.size
      else
        count = @map_terrain.size + 1
      end
  	else
      begin
	    count += 1
		if count >= @matrix.size
	      count = @matrix.size + 1
	      break
		end
      end until @matrix[count][0] == Robot.bomb
  	end
  	return count
  end
  
  def self.bomb
    0
  end

  def self.safe
    1
  end

  def self.boom
    6
  end

  def self.robot
    8
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
  use_threads = true
    # given an 'n' between min & max
    # total possible results: 2**n
    # a path can be constructed from binary values ranging from n-0's  .. n-1's
    # thus the values range from 0 - ((2**n)-1)
    # if the array is smaller than 'n', pad it w/ 0's
    # then, merely substitute D's for 0's and R's for 1's (or vice-versa)

    # here's a key piece of Ruby-Fu (did you know base-ten => binary was so
    # easy ?!):
    # (0 .. (n.size)).each { |slot| puts "slot: #{slot}: #{n[slot]}" }

    puts "\n\nsolving..." if @debug
    next_move = []
    # even_move:

    # first check if we've already got a solution to this map...
    #count = 0
    #@path = map.lookup_solution(min(),max()) || []
    @path = []

    if [] == @path
	  debug_level = 0
	  debug_level = 1 if @debug
      thread_ary = []
      #how-many 1's before we see a bomb
      first_bomb_right = moves_till_bomb('right')
      #how-many 0's before we see a bomb
      first_bomb_down = moves_till_bomb('down')
    if use_threads
servers_started = {}
ssh = Ssh.new

delete_list = []
#puts "initial server count: #{@servers.size}"
@servers.each_with_index do |server_info, idx|
  # what to do on this server !?!
  #puts "connecting... #{server_info.inspect}"
  ip = server_info['ip']
  u = server_info['u']
  port = server_info['port']
  ruby = server_info['ruby']
  dir = server_info['dir']

  pids_cmd = "/bin/ps -ewww -opid,command |/usr/bin/grep 'robot\_service\.'| /usr/bin/grep -v grep"

  if 1 == server_info['nokill']
    server = DRbObject.new_with_uri("druby://#{ip}:#{port}")
    expected = 'hi'

    begin
      thr = Thread.new do
        Thread.current["got"] = server.echo(expected).to_s
      end
      sleep 3
      if ( (false == thr.status) && (expected == thr["got"]) )
        next
      else
        thr.kill
      end
    rescue Exception => e
      puts "server.echo failed (#{ip}): #{e.message}"
    end
  else
    puts "kill set for #{ip}"
  end

  #puts "connecting to #{ip}..."
  ssh.connect(ip,u,@pwd)

  if (servers_started[ip].nil?)
    pids = ssh.connection.exec!(pids_cmd)
    if pids
      pid_array = pids.map do |pid_plus|
        pid = pid_plus[/^\s*(\d+)\s+/,1] || nil
      end
      pid_array.compact!
    else
      pid_array = []
    end
    if pid_array.size > 0
      #puts "found the following procs to kill on #{ip}: #{pid_array.inspect}"
  
      pid_array.each do |pid|
        #pid = pid_plus[/^\s*(\d+)\s+/,1]
        #if pid
          puts "\tremote kill: #{ip} - pid: #{pid}..."
          ssh.connection.exec! "kill -9 #{pid}"
        #else
        #  puts "no pid to kill..."
        #end
      end
      #sleep 1

      #else
      #  puts "no procs to kill on #{ip}: #{pid_array.inspect}"
    end
    sleep 1
  else
    puts "\t#{ip} already started..."
  end

  out = ""
  cmd = "/bin/sh #{dir}/start_robot_service.sh #{ruby} #{dir} #{port}"
  full_cmd = "/usr/bin/nohup #{cmd} >/tmp/out.log < /dev/null &"
  out = ssh.connection.exec! full_cmd
  sleep 3

  pids = ssh.connection.exec!(pids_cmd)
  if pids
    pid_array = pids.map do |pid_plus|
      pid = pid_plus[/^\s*(\d+)\s+/,1] || nil
    end
    pid_array.compact!
    puts "\tthe following procs on #{ip} are running: #{pid_array.inspect}"
    servers_started[ip] = 1
  else
    pid_array = []
    #puts "no procs are running on #{ip}: #{pids.inspect}"
    #puts "got: #{out}"
    puts "\ttried starting robot_service on #{ip}, port: #{port}, using full_cmd: #{full_cmd}"
    puts "\tpreparing to delete server: #{@servers[idx].inspect}"
    delete_list.push(idx)
    servers_started[ip] = nil
  end

  #if test fails
  server = DRbObject.new_with_uri("druby://#{ip}:#{port}")
  expected = 'hi'
  begin
    got = server.echo(expected).to_s
    delete_list.push(idx) if expected != got
  rescue Exception => e
    puts "\tserver.echo failed (#{ip}): #{e.message}"
  end
  
  #puts "closing..."
  ssh.close
end
delete_list.each do |idx|
  #puts "\tDELETING server: #{@servers[idx].inspect}"
  @servers[idx] = nil
end
@servers.compact!
#puts "server count: #{@servers.size}"

#sleep 3
#puts "\n\n solving matrix: #{@matrix.inspect}\n"
#puts "params: #{@instruct_options.inspect}"
    span_val = span() #no longer "middle value" but rather, the "span" from <min> -> <server1> -> ... -> <max>
#puts "full range: #{@min} - #{@max}; span: #{span_val}"
puts "\n\n\n"
      final = @min - 1
      (@min..(@max - span_val)).step(span_val) do |i|
        final = ((i + span_val) >= @max) ? @max : ((i + span_val) - 1)
        puts "thread_ary[#{thread_ary.size}] => [#{i} - #{final}] calling druby://#{@servers[thread_ary.size]['ip']}:#{@servers[thread_ary.size]['port']}"
        server = DRbObject.new_with_uri("druby://#{@servers[thread_ary.size]['ip']}:#{@servers[thread_ary.size]['port']}")
        thread_ary[thread_ary.size] = Thread.new do
          await_range = i..final
          #while true
          #@lock.synchronize {
            await_range.each {|await_num| add_awaiting(await_num) }
            #break
          #}
          #sleep rand
          #end
          
          s = thread_ary.size
          result_ary = server.get_binaries(i,(final),@matrix.size-1,@matrix[0].size-1, @matrix,first_bomb_right,first_bomb_down,debug_level)
          puts "thread_ary[#{s}], got result_ary: #{result_ary.inspect}"

          if result_ary.first
            # we're done!
            Thread.current["binary_str"] = result_ary.first
          else
            puts "...more work remains"
            #while true
            #@lock.synchronize {
              await_range.each {|await_num| remove_awaiting(await_num) }
              #break
            #}
            #sleep rand
            #end
            while true
              d = undoubled
              if d.nil?
                puts "all the work is done, or duplicated"
                break
              end
              puts "thread_ary[#{thread_ary.size}] => doubling-up on [#{d} - #{d}]"
              result_ary = server.get_binaries(d,d,@matrix.size-1,@matrix[0].size-1, @matrix,first_bomb_right,first_bomb_down,debug_level)
              if result_ary.first
                Thread.current["binary_str"] = result_ary.first
                break
              else
                #while true
                #@lock.synchronize {
                  remove_awaiting(d)
                  #break
                #}
                #sleep rand
                #end
              end
            end #end while
          end
        end
      end

      if final < @max
        server = DRbObject.new_with_uri("druby://#{@servers[thread_ary.size]['ip']}:#{@servers[thread_ary.size]['port']}")
        thread_ary[thread_ary.size] = Thread.new do
          await_range = (final + 1)..@max
          #while true
          #@lock.synchronize {
            await_range.each {|await_num| add_awaiting(await_num) }
            #break
          #}
          #sleep rand
          #end

          s = thread_ary.size
        puts "thread_ary[#{thread_ary.size}] => [#{(final + 1)} - #{@max}] calling druby://#{@servers[thread_ary.size]['ip']}:#{@servers[thread_ary.size]['port']} (f)"
          result_ary = server.get_binaries((final + 1),@max,@matrix.size-1,@matrix[0].size-1, @matrix,first_bomb_right,first_bomb_down,debug_level)
          puts "thread_ary[#{s}], got result_ary: #{result_ary.inspect}"

          if result_ary.first
            # we're done!
            Thread.current["binary_str"] = result_ary.first
          else
            puts "...more work remains"
            #while true
            #@lock.synchronize {
              await_range.each {|await_num| remove_awaiting(await_num) }
              #break
            #}
            #sleep rand
            #end
            while true
              d = undoubled
              if d.nil?
                puts "all the work is done, or duplicated"
                break
              end
              puts "thread_ary[#{thread_ary.size}] => doubling-up on [#{d} - #{d}]"
              result_ary = server.get_binaries(d,d,@matrix.size-1,@matrix[0].size-1, @matrix,first_bomb_right,first_bomb_down,debug_level)
              if result_ary.first
                Thread.current["binary_str"] = result_ary.first
                break
              else
                #while true
                #@lock.synchronize {
                  remove_awaiting(d)
                  #break
                #}
                #sleep rand
                #end
              end
            end #end while
          end
        end
      end
      puts "done calling...\n"
	  while [] == @path && thread_ary.size > 0
	    #sleep 0.01
	    sleep 1
	    delete_list = []
	    thread_ary.each_with_index do |thr,i|
	      if ! thr.status
          delete_list.push(i)
	        #thread_ary.delete(i)
	        if thr && thr["binary_str"]

	          #got what we wanted
              @path = binary_to_path( thr["binary_str"].split(//) )
              path_size = @path.size
              if path_size > @max
                tmp_path = @path[(path_size - max)..(path_size - 1)]
                puts "surgery... trimming #{@path.to_s} => #{tmp_path.to_s}"
                @path = tmp_path
              end
              puts "got path: #{@path}\n";

	          break
	        end
	      end
	    end #end thread_ary loop
      delete_list.each do |idx|
        thread_ary[idx] = nil
	    end
      thread_ary.compact!
	  end

	  #kill all other threads
	  thread_ary.each {|thr| Thread.kill(thr) }
    else
	  #former 2-lines:
	  binary_str = get_binaries(@min,@max,@matrix.size-1,@matrix[0].size-1, @matrix, first_bomb_right, first_bomb_down, debug_level ).first
      @path = ( binary_str.nil? ) ? [] : binary_to_path( binary_str.split(//) )
    end

      raise RuntimeError, "failed trying'" if [] == @path
      puts "got path: #{@path.inspect}" if @debug
      #idx = move_size > 0 ? count % move_size : 0
      #@path = next_move[idx] ? next_move[idx].call||[] : []
      #count += 1
    else
      puts "found previous solution" #if @debug
      return
    end

    # if we got this far then we were successful
	if @debug
    	puts "solved.\n\n\n"
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

  def span(min=@min,max=@max)
    #diff = max - min
    #return 1 if 0 == diff
    segments = @servers.size > @diff ? @diff : @servers.size
    segments = (0 == segments) ? 1 : segments
    puts "breaking range of #{@diff} into #{segments} segments..."
    span = @diff / segments
    while ((span * segments) < @diff)
      span += 1
    end
    puts "#{@min} - #{@max} => span: #{span}"
    span = (0 == span) ? 1 : span
    #min + ((max - min) / 2)
  end

  #
  # substitute R's & D's for 1's and 0's
  #
  def binary_to_path(binary_ary)
    puts "transforming binary: #{binary_ary.join}..." if @debug
    binary_ary.map {|digit| (digit.to_s == "0")? Robot.down() : Robot.right() }
  end

end

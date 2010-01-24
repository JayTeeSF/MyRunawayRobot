# sudo gem install ruby-prof
require 'rubygems'
require 'ruby-prof'

require 'test/unit'
require 'lib/robot'

class Stuff
  def setup
    @current_dir = '/Users/jonathanthomas/Desktop/Jan21/fun_robot'
    @impossible_config =  { :ins_min => 1, :ins_max => 1,
                            :terrain_string => ".XX.",
                            :debug => true,
                            :board_x => 2, :board_y => 2,
                            :only_config => true, :cache_off => true
                          }
    @down_config = @impossible_config.merge({:terrain_string => ".X.X"})
    @med_down_config = @impossible_config.merge({:board_x => 3, :board_y => 3, :terrain_string => ".X..X...."})
    @right_config = @impossible_config.merge({:terrain_string => "..XX"})
    @med_right_config = @impossible_config.merge({:board_x => 3, :board_y => 3, :terrain_string => "...XXXXXX"})

    @med_mix_config = @impossible_config.merge({:ins_max => 5, :board_x => 5, :board_y => 5, :terrain_string => ".XXXX..XXXX.XXXX..XXXX.XX"})
    @perf_config = @impossible_config.merge({:debug => false, :ins_max => 18, :ins_min => 11, :board_x => 30, :board_y => 30, :level => 55, :terrain_string => "....XX.X...XXXX.XX..X.XX..X..........X...XX...X..XX....X......XX.....X.X.X...........XX........X..XX.XX.XX...XX........X........X....X..X.XX.X.....XX........X...X.........X..X....XX.X.X..X....X.X.....XX.X...X.X..X..X..X..X.............XXX.X.....X.....X.X...X......X....X.X...X.XXX..X...........X...........XX.XXX....X..X...X..X...X.....X....X........XX..XX.X.....X.....XX...XXX.X.XX...X.....X..XX..X..XX..XX..X..X..X.X.X..X.......X..X..X.......X..X..X...X......XX...X....XX....X....XXX.......X......X.XX......X.X.XX.........XX.......X...X..X....X.X..X......X...X..X..XXX....X..........XX.X.....X..........XX.......X..XX..X....X.XXX..X.XX.XX.....X..X.....XXX....XX.X..........X............X.X.....XX......X....X..X..........X.X..XXXX....X.X.X..X.X.X.................XX.XX.X..XXXXXX.X.X....XXX.....X..X.X........XX..X.XX..X.XX....XX..XXXX..XXXX....X......XX............X.......X...X...X.X...XX............" })
    @perf_config_unk = @perf_config.merge({:use_known_bad => false})
    @long_perf_config = @impossible_config.merge({:debug => false, :ins_max => 17, :ins_min => 10, :board_x => 28, :board_y => 28, :level => 51, :terrain_string => "......X.....XX.XX.....X.X.......XX....XX.....X.X....X.XX.X..X.XX...XX.X...X.X..XX..X.....X......X...X.........X.X.X.......X.X...X..XX.......X.X.......X.....X..........X....X....X..X....X....X.....X.........X.X..X.X.X...XX.............X.....X..X.X....X..X...X....X...XX...XX.......X.......X.X.X.X...X.X..XXX......X..X.......XX.XXXX.X...X.X.......X......XX..........XX.X..XX.......XX..X.....X.........X..XX..X...X..X....X....XXX.........X..X..XX.XX.X...X.X...XX....X..XXXX.........X.X.X....X......X......XX...X...X.....X..XX...X.X........X....X..X....X..X..X..X....XX..XX...X..X.X...XX.....X.X.X..................X....X.XXX.X..X..XX.......X........X.X..X.X..XX.XX.....X...X...X..........X..X.....X...XXX...X.....X.X.....X........X.......X......XX....X...X..XX..X.......X...X...X....X.XX..."})
    @long_perf_config_unk = @long_perf_config.merge({:use_known_bad => false})
  end

  # determine if my path_generator works
  def test_for_all_paths
    puts "test_for_all_paths"

    puts "setup impossible robot"
    @robot = Robot.new @impossible_config
    paths_retrieved  = []
    next_move = @robot.path_generator
    while true
      got = next_move.call
      puts "got: #{got}"
      break if got.nil?
      paths_retrieved << got
    end
    puts "paths_retrieved: #{paths_retrieved.inspect}"
    assert_equal([['D'],['R']], paths_retrieved)
  end

  # eventually we need an expected time associated with this
  def test_performance
    puts "test_performance"
    expected_time_in_secs = 2.86554099999989
    perf_tests(expected_time_in_secs,@perf_config, 'w/ known cycles',1)
    #.merge(:debug => true)
    perf_tests(expected_time_in_secs,@perf_config_unk, 'w/o known cycles',2)

    #186.691902 - 149.783651
    expected_time_in_secs = 36.908251
    perf_tests(expected_time_in_secs,@long_perf_config, 'w/ known cycles',3)
    perf_tests(expected_time_in_secs,@long_perf_config_unk, 'w/o known cycles',4)
  end

  def perf_tests(expected_time_in_secs, config, msg='', counter=1)
    puts "setup performance(#{expected_time_in_secs}: #{msg}) robot"
    @robot = Robot.new config

    puts "test_performance_#{counter}"
    begin_time = Time.now
    assert_nothing_raised { @robot.solve }
    end_time = Time.now
    actual_time_in_secs = end_time - begin_time

    puts "actually took #{actual_time_in_secs} seconds vs. expected #{expected_time_in_secs} seconds."
    assert( expected_time_in_secs >= actual_time_in_secs )
  end

  # prove that we can solve the simplest of puzzles
  def test_possible_puzzles
    puts "test_possible_puzzles"

    puts "setup possible(right) robot"
    @robot = Robot.new @right_config

    puts "test_possible_puzzles_1"
    assert_nothing_raised { @robot.solve }

    puts "setup possible(m-right) robot"
    @robot = Robot.new @med_right_config

    puts "test_possible_puzzles_1b"
    assert_nothing_raised { @robot.solve }

    puts "setup possible(down) robot"
    @robot = Robot.new @down_config

    puts "test_possible_puzzles_2"
    assert_nothing_raised { @robot.solve }

    puts "setup possible(m-down) robot"
    @robot = Robot.new @med_down_config

    puts "test_possible_puzzles_2b"
    assert_nothing_raised { @robot.solve }

    puts "setup possible(m-mix) robot"
    @robot = Robot.new @med_mix_config

    puts "test_possible_puzzles_3"
    assert_nothing_raised { @robot.solve }
  end

  # no where to run...
  def test_fail_impossible_puzzle
    puts "test_fail_impossible_puzzle"

    puts "setup impossible robot"
    #@robot = Robot.new @impossible_config
    @robot = Robot.new @long_perf_config_unk
    @robot.solve

  end

  def profile_it(&block)
    RubyProf.measure_mode = RubyProf::WALL_TIME
    RubyProf.start

    block.call

    result = RubyProf.stop
    printer = RubyProf::CallTreePrinter.new(result)
    printer = RubyProf::GraphHtmlPrinter.new(result)
    datetime = Time.now.strftime("%Y%m%d%H%M%S")
    #file = File.open("#{@current_dir}/profile-tree_#{datetime}.prof", "w")
    file = File.open("#{@current_dir}/profile-graph_#{datetime}.html", "w")
    printer.print(file)
    #, 0)
    file.close
  end
end
  s = Stuff.new
  s.setup
  #s.profile_it { s.test_fail_impossible_puzzle }
  s.profile_it { s.test_fail_impossible_puzzle }

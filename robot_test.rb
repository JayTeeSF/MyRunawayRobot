require 'test/unit'
# require './lib/map.rb'
require './lib/robot.rb'

class RobotTest < Test::Unit::TestCase

  # NOTE: though automated testing of regx's is appropriate
  # I manually used rubular.com to test my regx's <-- because I do not
  # anticipate needing to change this code -- after today

  def initialize(*args)
   @pwd = ""
   super(*args) 
  end

  def setup
    @pwd ||= Robot.prompt("pwd?",:pwd => true)
    @impossible_config =  { :ins_min => 1, :ins_max => 1,
                            :terrain_string => ".XX.",
                            :pwd => @pwd,
                            :debug => true,
                            :board_x => 2, :board_y => 2,
                            :only_config => true, :cache_off => true
                          }
    @huh_config = @impossible_config.merge({:terrain_string => "..XX.....", :ins_max => 2, :ins_min => 2,
      :board_x => 3, :board_y => 3, :level => "0"})
    # Found it (["D", "R"])!
    #   0           [3,3]    (2..2)                                 DR  1.397443
    
    
    @down_config = @impossible_config.merge({:terrain_string => ".X.X"})
    @med_down_config = @impossible_config.merge({:board_x => 3, :board_y => 3, :terrain_string => ".X..X...."})
    @right_config = @impossible_config.merge({:terrain_string => "..XX"})
    @med_right_config = @impossible_config.merge({:board_x => 3, :board_y => 3, :terrain_string => "...XXXXXX"})

    @med_mix_config = @impossible_config.merge({:ins_max => 5, :board_x => 5, :board_y => 5, :terrain_string => ".XXXX..XXXX.XXXX..XXXX.XX"})
    @broken_config = @impossible_config.merge({:terrain_string => "...XXXX..X.X.............X.XX.....XX", :ins_max => 4, :ins_min => 3, :board_x => 6, :board_y => 6 })
    @broken_config4 = @impossible_config.merge({ :terrain_string => ".X.........X..X..........XX...X...XX..............XX....X...XX...X.X.X.XXXXX...X..X.......X.....................X.X...X....XX..X............X...X........X...X.X...............X......X...XX.X...X.X....XX..X.XX.X.........X.X...X....X.........X..X.X.X..X...XXX...XX.....XXX..X....X....X.....X..X.X......X.XXX.....X..X.X.X..XX..XX..X.X..X.X..X.XX.......XX......XX..X..XX....X.XXX...X..X.......X.XXX..XX.....X...XX..X.X..X....XX.X.X...X.X....X.X.", :ins_max => 13, :ins_min => 8, :board_x => 21, :board_y => 21 })
    @broken_config2 = @impossible_config.merge({ :terrain_string => ".....X.XXX...XXX..X............................X...X..X....X..X.....X.X.X...X..........X.X.XX...XXXXX..XX............XXXX.XX.X..X.XXXX......X..........X..X.XX.XX..X.....X...X.X.X..XX..X..XXX.X...X...X....X..XXX...............X..X..XX........X....X......XX.....X......X.X...........XXX........XXX...X.XX....X.....X...XX....X..X.XX..X.........X....XX....X.X...........X....X........X..XXXX.......XXX.....X......X.X.......XXX.....XX..X.X..XX..X....XX...X...X.....X.X.....X..X.......X...X......X..X.XX..X.....X..XX...X.......XX.X.X.........XX....X..X....X..X.XX..X.X..X.X..X.X...........XX........X....X............X.X..X.X...XX.", :ins_max => 15, :ins_min => 9, :board_x => 25, :board_y => 25 })
    @broken_config3 = @impossible_config.merge({ :terrain_string =>
	"..................X.....XXX...X....X...XX.X.......XXX...X...X......X.........X.X.X....XX.....X.X....X...XXX.X...X.....X......XX..............X...X.....X........X..XX......X....X.X....X......XX.XX..XX....X.............X..........X...X...X...X............X.XX.X.X.....X.X..X.X.X...X.X..X.X.XX..X...X...X...X...........X..X...X.X....X...X...X...XX.........X..X.X.XX...............X........XX..X....X....XXX...X.........X.......X...XX.XX..XX...X........X....X.....XXX......X...X.X.......X...........XXX..X.X..XXX...X.X.X.X.X.X.............X...X......XX...X..X.X.X...X........X..X....XX......X...X......XX.......X........XX.....X.....X....X.X....X....X...X.X.X...XX......X.............X.....X....X...X...........X....XX......XX....X...........X...X................X...X.....X.............X.X....X............X.......X.X....X.....XX...XXX..XX...X......X...XX............X..........X...XXX...X.....X.....X.......X.X...............X...X......X......XX..........X..X..X...X.......X....X........X..X.X....X.X.X.....X..X.X.X.XXX.X........XX.....X.....X.......X....X..X....XXX.X...X.X.......X..........................X.X......X.....X......X........XXX.............X...X..X.....X..X.XX.....X...X.....X..X....X.X...........X.X.X......X...X.........X..X.XX....X...X...X.............X....X.X...X.X.....XX...........XXX..........XX..X.X..X....X..XX...XX.................X..X.X..XXX.XX...XXX................XX..X.X.......X.......X.X.XX..........X.......X..X.....X..X....X..X.....X.X..X..XX.X..XX.....XX.XXX.................X......X................X.X...X......XX...X......................XX.....X...X...X.......XX.......XX.......XX...............X............X...X..........X..XX.........X.X.X.....................X.......X.X.X..XXX.....X..........XXX....X....X.....XX.X...XXX.....X..............X.XX........X.XX...................X.........X..X........X.XXX...X..XXX.....XXX.......X.....XXX...X..XX.X.XX.X.X...X.....XX...X.XXX.XX.X........X..X...X....X.......XXX.....X....X..X..X........X..X....XX........X......X......XX....X....X...XX.........X.X..X...............X.X...X.................XX..X..X..XX.XXX.X..........................X....X..X.X.........XX.............X.......XXX..X....XXX....X........X....X...X..........XX...X...X.........X...X........XX....XX.................X..XX....X..X.....X...........X.X...X..X...X....XX....X....X.X...X..X.X.XX.X.................X..X.....X..XXX..X...........X....X...XX.X..X..............X..X..X.......X....X..X..X.X...........X.X.......X..XX..XX..X....X.X..X.........X..X......X...XXX.X.XX......X.X........XX....X..X...XX.XX...........XX.X......................X......X....XXXX....XX...X....X.....XX...X.XX.XX...........XX..XX....XX...X.....X.X..X...........X...X....XX.....X..X.....X....X..............XX.X...X......X...XXX.XX..................X.XX.....X..X..X.X............X.X...X...................XXX......X.......X...XX....X.X.XX..X.X..X.........X.........X...X......XX.....X...X...XX............X..X.....X.X.....XXX............XXX.......X....XX...X..........X.......XX.......X.X...XX....X.X.X......X..........XX.XX.........XX.X......X...X..X......X...X....X..X.X..XX.......X.......X.................X.X...X.....X.......X....X.....X...X..................X.XX.X..X....X.............X..XX..X.......XX....XX...X.....XX.X...XXX...X..........X...........X...X.......X.X..X..X...X...X.X.X......X....X...X..X............X.X..X.X.X..X...X...X.X.....X..........XX....X.............XX........X.X.X.XX......X..X..X......X..X...X...X.X...X....X.X...XXX..X....",
	:ins_max=>34, :ins_min=>20, :board_x=>59, :board_y=>59 })
    @super_hard_config = @impossible_config.merge({ :debug => false, :terrain_string => "...X.X.......XXX..XX.......X.X..X.X.XX......X.X.X..........XX.X..XX.X..X..X.XX.....XX.X..X......X.XX...X.....XX...X..X..XX..X..XX.................X........X..X.........X..X.X.X....X.XXX.X.XX.X.X....XX..X.....X......X...X..X......X......X.X..X..X...X...XXX..X..X.X..X........X.........X.X.........X...X.XXXX....XX.......X....X..X.....X..X.XXX...XX.....X.....XX.XX..X.X.X....X.........X..XX..X...X.X.XX.......X........X......XX........X..X..X......X.X.....X..XXXX..X.X..X.X....XX.XXX.X...X..X.............XX..X.......X...X....XX.X.XXX....X.......X.....X.X....X....X...X..........X........X....XX........X..........X...X.X.X....XX...X.....XXX................X.X....XX....X....X....X.....X.X..XX.X...XXXXX....XX.X...X..X.....X................X.XX.X....XXXXXX....X.......XX...X..X...XX..X..X.....X.X..X...X....X.X......X....X.................X...XX..X......X.X.....XX...XX.X........X...X.XXX....X.......XXX..X.....XX..X....X.....XX.X..X..X...X.XXX..XXX...XX.....X..XX..X.X.....X..X...XX.......X.X..XXX.X..X..XX....X...X..X..XX.....XX......X...X...X.....X.X.........XXX.X.....X...........X...X...XX...........X.......X.....XX......XX...X..X.X...X.X....X..XXX.........XX....XX.XX..................X.XX.....X..XX.........XXXX.......X.XX...X...X.X.X.........X..X..XX..X...X..X...X.X.X.......X.X.XXX.X........X......X..XXX.....X...X...X...X..X.....X....X..........XX....X..XX....XXX...X....XX..X.X..X.....X.......X..X.....X..XX.X......X.....X......X...X.X..XX.....XX...X...XX...X.X......X.X....X...X.......XXX.X.X......X.....XX.XX...X.X....X....X.X.X.......X...X...X.X.....XX.....X...........XX.....XX.X......X...X....XX..X.......X....X....X....XX..X.....X..XX.X.X...X..X.X.XX.X......XX...XXX.X......XXX..X...X...X........X....XX.X......X.X.X..X....X....X......X.X.X..........X.X...X.....X...XX.........XX..XX.X..X....X....X......X....X..X.......XX..X.X..XX..........X....X......XX........X...X...X.X.X.XX.....X...X.X..X.....X..X..X...........X.X...X.......X...XXX...XX.X.......X....X...X.X.X.XXX..X...X.X...X....X.X..X..X..XXX.X...........X.X......X..XX..X.XX......X...X..X.X.....XX.....XX..X.X....XX....X.X....X..............X.X.X.X....X.............X........X..XXX......XX..X....X...X......X.XX...........X....X...X.X..X....XXX..X..X.X..............X.X...X.XXXX......X.X.......XX.X..XX.X..X.XX....X.X...XXX..X............X...X.XX.X.X....................XX.X...X..X...X..X.....X......XXX.X....X.X.X...X....X........X.............XX..X.X....XX.X.X.........X.X.........X.........X...X.XX......X..XXX.X.X.X....XX.......X.....XXXXX.X....XX....XX....X..X...X...XX.X.............XX.....X.X......X.X..X.......X..XX........XX.X..XX..X..X...X.........X..X........X.......X...X.......X..X....X.XXX....X......X...XX........X.XX.....X......X.........X.X.XXXXX.....X..X.......X.X......X..X..X...X..X..X.....XX.....X...X..X........", :ins_max => 31, :ins_min => 18, :board_x => 53, :board_y => 53 })
    @hard_config = @impossible_config.merge({ :debug => false, :board_x => 38, :board_y => 38, :level => 71, :terrain_string => ".....XX.X...X....X...XX....X...XX....X..X.....XXXX..X.X....X...X.X....X....X.....XXXXX....X....X...X.....XXXX......XX.X..X......X.......X.XXX.XX.XX..X...X...XX...XX..X..X..........X.X...XX....XX......X.X..XX.XX.X.......X......X...X.X...............X.X......X...X...........XX...X...XXX...X..........X.........XX..X..X.XX..X..X....X........X.....X....X......X.XX.......X..X.....X.X.........X..XX...........XX.....X.XX...........X.............X.XX.X.....X....X.X..X.X.X.........X.....X......X.........X...X..X...X....X......XXX.X......X.X..X........XX........XX.X.......X.X....X.X.X...X..XX....X....X..X........X..X...X..XX.XX..X...XXX...XX..X.X...XXX....X....X.X...XX.XXXX........XX....X.....XX..X...X....X..X..X.X........X......X..XX...XX....X......X.XXX.X....X....X...X..........XX..........XXX.X.X..X..X.X.....X.X.X.X.X.X..XX.X....X....X.....X.XX.X....X.X..X.X.XX..X...X.X..X...X.X.X..X.XX.XX...X.X.X.X......X.........X..XX....XXXX....X.X...X.X....XX....X........X..XX.....X.......X...XX....X..X......X..XXXX......X....XX..X...X.....X........X....X..X.X.X.X..X...X.X...X....XXX.X........X..XXX...X..............X.X......X....X.....XXX....XX..X..X.......X....XXX..X.X.....X.....X..X...X....X..XX.............X.......XX.....X.....X......X..X.....XX.X......X.......X....X...X..X...............XX.X.....XXX..........X.X.........X....X..XX....X.X..X.......X....XX..X..XXX.....X...XXX..X...X..X..........X.....X..XX.XX.XXX..X..X...XX..XX...X...X.X.", :ins_max => 22, :ins_min => 13 })
    @perf_config = @impossible_config.merge({:debug => false, :ins_max => 18, :ins_min => 11, :board_x => 30, :board_y => 30, :level => 55, :terrain_string => "....XX.X...XXXX.XX..X.XX..X..........X...XX...X..XX....X......XX.....X.X.X...........XX........X..XX.XX.XX...XX........X........X....X..X.XX.X.....XX........X...X.........X..X....XX.X.X..X....X.X.....XX.X...X.X..X..X..X..X.............XXX.X.....X.....X.X...X......X....X.X...X.XXX..X...........X...........XX.XXX....X..X...X..X...X.....X....X........XX..XX.X.....X.....XX...XXX.X.XX...X.....X..XX..X..XX..XX..X..X..X.X.X..X.......X..X..X.......X..X..X...X......XX...X....XX....X....XXX.......X......X.XX......X.X.XX.........XX.......X...X..X....X.X..X......X...X..X..XXX....X..........XX.X.....X..........XX.......X..XX..X....X.XXX..X.XX.XX.....X..X.....XXX....XX.X..........X............X.X.....XX......X....X..X..........X.X..XXXX....X.X.X..X.X.X.................XX.XX.X..XXXXXX.X.X....XXX.....X..X.X........XX..X.XX..X.XX....XX..XXXX..XXXX....X......XX............X.......X...X...X.X...XX............" })
    @perf_config_unk = @perf_config.merge({:use_known_bad => false})
    @long_perf_config = @impossible_config.merge({:debug => false, :ins_max => 17, :ins_min => 10, :board_x => 28, :board_y => 28, :level => 51, :terrain_string => "......X.....XX.XX.....X.X.......XX....XX.....X.X....X.XX.X..X.XX...XX.X...X.X..XX..X.....X......X...X.........X.X.X.......X.X...X..XX.......X.X.......X.....X..........X....X....X..X....X....X.....X.........X.X..X.X.X...XX.............X.....X..X.X....X..X...X....X...XX...XX.......X.......X.X.X.X...X.X..XXX......X..X.......XX.XXXX.X...X.X.......X......XX..........XX.X..XX.......XX..X.....X.........X..XX..X...X..X....X....XXX.........X..X..XX.XX.X...X.X...XX....X..XXXX.........X.X.X....X......X......XX...X...X.....X..XX...X.X........X....X..X....X..X..X..X....XX..XX...X..X.X...XX.....X.X.X..................X....X.XXX.X..X..XX.......X........X.X..X.X..XX.XX.....X...X...X..........X..X.....X...XXX...X.....X.X.....X........X.......X......XX....X...X..XX..X.......X...X...X....X.XX..."})
    @long_perf_config_unk = @long_perf_config.merge({:use_known_bad => false})
  end

  # determine if my path_generator works
  #def test_for_all_paths
  #  puts "test_for_all_paths"

  #  puts "setup impossible robot"
  #  @robot = Robot.new @impossible_config
  #  paths_retrieved  = []
  #  next_move = @robot.path_generator
  #  while true
  #    got = next_move.call
  #    puts "got: #{got}"
  #    break if got.nil?
  #    paths_retrieved << got
  #  end
  #  puts "paths_retrieved: #{paths_retrieved.inspect}"
  #  assert_equal([['D'],['R']], paths_retrieved)
  #end

  def test_navigation
    # @down_config = @impossible_config.merge({:terrain_string => ".X.X"})
    puts "setup down_config"
    @robot = Robot.new @down_config

    # puts "map row0: #{@robot.map.matrix[0]}"
    assert(@robot.map.matrix[0][0] == Map.safe)
    # puts "map row0col1: #{@robot.map.matrix[0][1]}"
    assert(@robot.map.matrix[0][1] == Map.bomb)
    

    # puts "map row1: #{@robot.map.matrix[1]}"
    # puts "map row0col0: #{@robot.map.matrix[1][0]}"
    assert(@robot.map.matrix[1][0] == Map.safe)
    # puts "map row0col1: #{@robot.map.matrix[1][1]}"
    assert(@robot.map.matrix[1][1] == Map.bomb)

    # puts "should be able to move down, but not right"
    row=col = 0
    # puts "I shall go down from r:#{row}/c:#{col}"
    assert(@robot.map.avail?(Robot.down(), row,col) )
    # puts "I shant go right from r:#{row}/c:#{col}"
    assert(! @robot.map.avail?(Robot.right(), row,col) )
  end

  # eventually we need an expected time associated with this
  # REE: Finished in 16.276319 seconds.
  # 1.9.2: Finished in 5.459060 seconds.
  # jRuby 1.4: Finished in 5.345 seconds.
  # jRuby 1.5.1: Finished in 4.799 seconds.
  
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

def test_huh
  puts "setup huh robot"
  @robot = Robot.new @huh_config
  puts "test_possible_puzzles_huh"
  assert_nothing_raised { @robot.solve }
end

  # prove that we can solve the simplest of puzzles
  def test_possible
    puts "test_possible_puzzles"
=begin
=end

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

  # xxx
  def test_super_hard
    puts "setup possible(hmm-super_hard) robot"
    @robot = Robot.new @super_hard_config

    puts "super_hard_test_1"
    assert_nothing_raised { @robot.solve }
  end

  # these are hard tests (long) 179secs...
  # yet, only 87 secs in ruby1.9!!
  # soln: DDDDDDDDDDRRDDDDDRDDR 
  def test_hard
    puts "setup possible(hmm-hard) robot"
    @robot = Robot.new @hard_config

    puts "hard_test_1"
    assert_nothing_raised { @robot.solve }
  end

  # these are tests that broke previously
  def test_regress
    puts "setup possible(hmm-brok) robot"
    @robot = Robot.new @broken_config

    puts "test_regress_1"
    assert_nothing_raised { @robot.solve }

    @robot = Robot.new @broken_config2.merge(:debug => false)

    puts "test_regress_2"
    assert_nothing_raised { @robot.solve }

    @robot = Robot.new @broken_config4.merge(:debug => false)

    puts "test_regress_4"
    # assert_nothing_raised { @robot.solve }
    puts @robot.solve
    
    rs = @robot.path.size
    assert(rs >= @broken_config4[:ins_min] && rs <= @broken_config4[:ins_max], "path is #{rs} and it's suppose to be in the range #{@broken_config4[:ins_min]}..#{@broken_config4[:ins_max]}")
=begin
    @robot = Robot.new @broken_config3.merge(:debug => false)

    puts "test_regress_3"
    assert_nothing_raised { @robot.solve }
=end

  end

  # no where to run...
  def test_impossible
    puts "test_impossible_puzzle"

    puts "setup impossible robot"
    @robot = Robot.new @impossible_config
# puts @robot.solve
    assert_raise(RuntimeError) { @robot.solve }
  end

end

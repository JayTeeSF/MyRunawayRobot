require 'test/unit'
require './lib/robot.rb'

class RobotLongPerformance < Test::Unit::TestCase

  def setup
    #REE config:
    #unless GC.copy_on_write_friendly?
    #  puts "making friendly..."
    #  GC.copy_on_write_friendly = true
    #end
    @impossible_config =  { :ins_min => 1, :ins_max => 1,
      :terrain_string => ".XX.",
      :debug => true,
      :board_x => 2, :board_y => 2,
      :only_config => true, :cache_off => true
    }
        @level_119_config = @impossible_config.merge({:debug => false, :terrain_string => "..........X.X.X........XX..XXX....XX..XX.......X.X..X..XX.X....X...XX........XXX................X..........X.......X........X......................X..XXX...............X..XX............X.X.......X.X...X....X.X....X...X..X.X.X................X..X.X.....X......XXX....X........X..........X......X..............X...X.....X........XXX...XX...............X.X...XX..XX.......XX.....X......X.X.XX.....XXX.......X..X...X.X..XX.........X............X....X......X.XX.....X...X......X.X...X.XXX..X..X....X.X.X.....X....X.........XX.X..X....X..X..........X...X..............X.X.......XX..X........X.X.....XX......X..X..X..X....X..XX.XX..XX.X....X........X.....X.........X...XX.X....X.......X.X..X....X.X....X.......XX...........X..X.X....X..XX....XX.......X..X.XX...........X.........................X.X..X.X....XX..XX...XX.X..X.........X....X.........X....X.XXX.X.X............XX......XX..XX..X..X.X....X......X.....XX.................XXX..............XX.....X................X....XX.X........XX..............X..X....X.....X.....X....X.......X.XX.....XXXXX........X......X..X...XX.X..XX..X.XXX..X..X....X....X......X.................X....X.....X.........X...............X........X...XXXX....XX...X...XXX...X....XX.......X....X........X.....X..X.X......XXX.XX...X.......X...X................X.........XX...........X...............X..........X....X....X...XXX.X...X.XX.....X................X....XX..X.XX....X...........X..X.X......X.......XX........X........XX....X..........X.X.XX.........X.X..X....X...X.X..........X...............X......X....XX.X.............X..........X..X..XXX..XX...........X.......X...X..X......X..XX....X............XX..............X...X...X.X.......XXX............XXX.X..X...XX...X...........X...........X..X.X............X.X.....X....X..X.X.XX.............X................X.X.X..........XX.........X......XX.X.X....X.X..X.X.X....X.............X.X.XX.........X..X.XX.XX..........XX......X..X....X.X......XXX.X.X.X......XXX...XX..................X.........X.....X...X.....X..........X....X.X.XX....X.......X...XXXX...X..........XX..X............X.....X.XX.....X..X..........X.....X......X....X.....X.X.X...X.X..XX.X.....X....X.........XX..X....X.X.X.XXX....X..XX...X.XXX....X...XXXX....X......XX..........X........X..X.X....XX........X...XX....X...XX.....X......X..X......X..XX.......X........XX....X....X.........X..........X...X..X.X.....X....X......X......X.X...X............................X..X......X......X.X..........X......X.X........X..X.....X....X......X...XX.X.X..X......X.X..XX..........XXX.....X..X.....X..X....X..X..X..X.X..X......X.....X.....X.X...X.........XXX...X..X.X.X.X.........X..........XX..X..X..XXX...XX.......X...........X....X.......X.....X.............X......X.......X....XX.....X...X....X.......XX...XX.XX................XX..X.....X.X.......X......X...........XXX.....X.X..X....X.............X...XX...X............X.......X..X....XX..XX...X.X.XX...............X.X..X.......................XX.........X........X.X........X....X.......X.................XX...XX..X.X........XX.X...X...........X...X.......XXX......................................XX..X...X....X..X...X...X...XX..XXXX....X..........XX.XXX..X...X.....X.X.X...XX....X..X..X...X.X.....X......XX.XX.X.X.X...............XX.XX.X......X.......X......XXXXX.XX.........................X...X.....X...XX.......X...X...............X...X....X.....X...........X...........X.......X...X..........X...............XXX........X........XX...X..X.XX.X..X.X....X.X.......X...X.....X.XX.X.X.X........X.X.X...X.....X.X........X.............X...............X.XX.X........X.X......X..X...X..X.......XX.....X.......X.X.XX.......X.X....X.X.....X..X.....X......X.........X..XX...X.X...XX..X..X....XX...............X..X..X....X..X.....X.X.XX....X.....XXX.......X..XX...X..X.X.............X..X.........X.....X....XX....X.X.......X..XX....X.X.......X.......X..............", :ins_max => 36, :ins_min => 21, :board_x => 62, :board_y => 62 })
      end

      def test_long_performance
        # rbx-1.0.1 143.73234
        # rbx-1.0.1 (w/ fill-in dead-ends): 127.784013 vs. 1.9.2: 157.334751
        # rbx-1.0.1 (ruby --no-rbc): 125.868788
        # rbx-1.0.1 116.897795
        expected_time_in_secs = 116.897795 # new personal best: 242.912, bog:202.738, bog:163.7; wha?: 256.265; k: 203.64; hmm: 207.532; k: 161.941
        perf_tests(expected_time_in_secs, @level_119_config, 'level 119 (via fast-jRuby)', 5)
      end

      def perf_tests(expected_time_in_secs, config, msg='', counter=1)
        puts "setup performance(#{expected_time_in_secs}: #{msg}) robot"
        @robot = Robot.new config

        puts "test_performance_#{counter}"
        begin_time = Time.now
        assert_nothing_raised { @path = @robot.solve }
        end_time = Time.now
        actual_time_in_secs = end_time - begin_time

        puts "actually took #{actual_time_in_secs} seconds vs. expected #{expected_time_in_secs} seconds: #{100 * (1.0 - actual_time_in_secs / expected_time_in_secs)}% decrease."
        assert( expected_time_in_secs >= actual_time_in_secs )
        assert( @path && !@path.empty?)
        puts "got: #{@path}"
      end

end

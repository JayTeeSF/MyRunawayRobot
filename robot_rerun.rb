require 'test/unit'
# require './lib/robot.rb' # for 1.9.2
require 'lib/robot.rb' # for rbx

# ruby /robot_rerun.rb -n test_98 -- 10
class RobotRerun < Test::Unit::TestCase

  def setup
    @base_config =  { :ins_min => 1, :ins_max => 1,
      :terrain_string => ".XX.",
      :debug => true,
      :board_x => 2, :board_y => 2,
      :only_config => true, :cache_off => true
    }
    
    @config = generate_config("./run_configs.txt")
    # puts "got config...: #{@config.inspect}"
  end

  def generate_config(file_path)
    config = {}
    conf_file = File.open(file_path)

    level = 0
    puts "reading config file"
    while conf_line = conf_file.readline
      level += 1
      config[level] = @base_config.dup
      config[level].merge!(eval(conf_line.chomp))
      print "."
    end    
  rescue EOFError
    puts "!"
  ensure
    conf_file.close
    return config # apparently return(s) must be explicit from an ensure block...
  end

  def test_long_performance
    # rbx-1.0.1 143.73234
    # rbx-1.0.1 (w/ fill-in dead-ends): 127.784013 vs. 1.9.2: 157.334751
    # rbx-1.0.1 (ruby --no-rbc): 125.868788
    # rbx-1.0.1 116.897795
    # shrunk range of acceptable paths: 9.978728
    expected_time_in_secs = 9.978728 # new personal best: 242.912, bog:202.738, bog:163.7; wha?: 256.265; k: 203.64; hmm: 207.532; k: 161.941
    
    level_119_config = @base_config.dup.merge({
      :expected_time_in_secs => expected_time_in_secs,
      :debug => false, :ins_max => 36,
      :ins_min => 21,
      :board_x => 62,
      :board_y => 62,
      :terrain_string => "..........X.X.X........XX..XXX....XX..XX.......X.X..X..XX.X....X...XX........XXX................X..........X.......X........X......................X..XXX...............X..XX............X.X.......X.X...X....X.X....X...X..X.X.X................X..X.X.....X......XXX....X........X..........X......X..............X...X.....X........XXX...XX...............X.X...XX..XX.......XX.....X......X.X.XX.....XXX.......X..X...X.X..XX.........X............X....X......X.XX.....X...X......X.X...X.XXX..X..X....X.X.X.....X....X.........XX.X..X....X..X..........X...X..............X.X.......XX..X........X.X.....XX......X..X..X..X....X..XX.XX..XX.X....X........X.....X.........X...XX.X....X.......X.X..X....X.X....X.......XX...........X..X.X....X..XX....XX.......X..X.XX...........X.........................X.X..X.X....XX..XX...XX.X..X.........X....X.........X....X.XXX.X.X............XX......XX..XX..X..X.X....X......X.....XX.................XXX..............XX.....X................X....XX.X........XX..............X..X....X.....X.....X....X.......X.XX.....XXXXX........X......X..X...XX.X..XX..X.XXX..X..X....X....X......X.................X....X.....X.........X...............X........X...XXXX....XX...X...XXX...X....XX.......X....X........X.....X..X.X......XXX.XX...X.......X...X................X.........XX...........X...............X..........X....X....X...XXX.X...X.XX.....X................X....XX..X.XX....X...........X..X.X......X.......XX........X........XX....X..........X.X.XX.........X.X..X....X...X.X..........X...............X......X....XX.X.............X..........X..X..XXX..XX...........X.......X...X..X......X..XX....X............XX..............X...X...X.X.......XXX............XXX.X..X...XX...X...........X...........X..X.X............X.X.....X....X..X.X.XX.............X................X.X.X..........XX.........X......XX.X.X....X.X..X.X.X....X.............X.X.XX.........X..X.XX.XX..........XX......X..X....X.X......XXX.X.X.X......XXX...XX..................X.........X.....X...X.....X..........X....X.X.XX....X.......X...XXXX...X..........XX..X............X.....X.XX.....X..X..........X.....X......X....X.....X.X.X...X.X..XX.X.....X....X.........XX..X....X.X.X.XXX....X..XX...X.XXX....X...XXXX....X......XX..........X........X..X.X....XX........X...XX....X...XX.....X......X..X......X..XX.......X........XX....X....X.........X..........X...X..X.X.....X....X......X......X.X...X............................X..X......X......X.X..........X......X.X........X..X.....X....X......X...XX.X.X..X......X.X..XX..........XXX.....X..X.....X..X....X..X..X..X.X..X......X.....X.....X.X...X.........XXX...X..X.X.X.X.........X..........XX..X..X..XXX...XX.......X...........X....X.......X.....X.............X......X.......X....XX.....X...X....X.......XX...XX.XX................XX..X.....X.X.......X......X...........XXX.....X.X..X....X.............X...XX...X............X.......X..X....XX..XX...X.X.XX...............X.X..X.......................XX.........X........X.X........X....X.......X.................XX...XX..X.X........XX.X...X...........X...X.......XXX......................................XX..X...X....X..X...X...X...XX..XXXX....X..........XX.XXX..X...X.....X.X.X...XX....X..X..X...X.X.....X......XX.XX.X.X.X...............XX.XX.X......X.......X......XXXXX.XX.........................X...X.....X...XX.......X...X...............X...X....X.....X...........X...........X.......X...X..........X...............XXX........X........XX...X..X.XX.X..X.X....X.X.......X...X.....X.XX.X.X.X........X.X.X...X.....X.X........X.............X...............X.XX.X........X.X......X..X...X..X.......XX.....X.......X.X.XX.......X.X....X.X.....X..X.....X......X.........X..XX...X.X...XX..X..X....XX...............X..X..X....X..X.....X.X.XX....X.....XXX.......X..XX...X..X.X.............X..X.........X.....X....XX....X.X.......X..XX....X.X.......X.......X.............."
    })

    try level_119_config
  end
  
  def test_119
    try :level => 119, :expected_time_in_secs => 18.408216
  end

  def test_131
    try :level => 131, :expected_time_in_secs => 1378.578018
  end

  def test_120
    try :level => 120
  end

  def test_136
    try :level => 136
  end

  def test_15
    try :level => 15
  end

  def test_10
    try :level => 10
  end

  def test_9
    try :level => 9
  end

  def test_8
    try :level => 8
  end

  def test_7
    try :level => 7
  end

  def test_6
    try :level => 6
  end

  def test_5
    try :level => 5
  end

  def test_4
    try :level => 4
  end

  def test_2
    try :level => 2
  end

  def test_3
    try :level => 3
  end

  def test_26
    try :level => 26
  end

  def test_34
    try :level => 34
  end

  def test_1
    try :level => 1
  end

  def test_106
    try :level => 106
  end

  def test_105
    try :level => 105
  end

  def test_104
    try :level => 104
  end

  def test_140
    try :level => 140
  end

  def test_141
    try :level => 141
  end

  def test_98
    try :level => 98
  end

  def test_all_levels
    @config.keys.sort.each do |level|
      try :level => level
    end
  end

  def try options = {}
    options.merge({ :debug => false })
    options[:ideal] = ARGV[0] if ARGV[0]
    level = options[:level]
    expected_time_in_secs = options[:expected_time_in_secs]
    
    robot_config =  level ? @config[level].merge(options) : options
    @robot = Robot.new robot_config

    puts "returning path - min: #{@config[level][:ins_min]} max: #{@config[level][:ins_max]}"
    puts "\n\nstarting level #{level}..."
    begin_time = Time.now
    assert_nothing_raised { @path = @robot.solve }
    end_time = Time.now
    actual_time_in_secs = end_time - begin_time
    
    if expected_time_in_secs
      puts "actually took #{actual_time_in_secs} seconds vs. expected #{expected_time_in_secs} seconds: #{100 * (1.0 - actual_time_in_secs / expected_time_in_secs)}% decrease."
      assert( expected_time_in_secs >= actual_time_in_secs )
    else
      puts "actually took #{actual_time_in_secs} seconds."
    end

    assert( @path && !@path.empty?)
    # GC.start
  end
end

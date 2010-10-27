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

  def test_120
    try 120
  end

  def test_136
    try 136
  end

  def test_10
    try 10
  end

  def test_9
    try 9
  end

  def test_8
    try 8
  end

  def test_7
    try 7
  end

  def test_6
    try 6
  end

  def test_5
    try 5
  end

  def test_4
    try 4
  end

  def test_2
    try 2
  end

  def test_3
    try 3
  end

  def test_1
    try 1
  end

  def test_106
    try 106
  end

  def test_105
    try 105
  end

  def test_104
    try 104
  end

  def test_140
    try 140
  end

  def test_141
    try 141
  end

  def test_98
    try 98
  end

  def test_all_levels
    @config.keys.sort.each do |level|
      try level
    end
  end

  def try level
    options = { :debug => false }
    options[:ideal] = ARGV[0] if ARGV[0]
    @robot = Robot.new @config[level].merge(options)

    puts "returning path - min: #{@config[level][:ins_min]} max: #{@config[level][:ins_max]}"
    puts "\n\nstarting level #{level}..."
    begin_time = Time.now
    assert_nothing_raised { @path = @robot.solve }
    end_time = Time.now
    actual_time_in_secs = end_time - begin_time
    puts "actually took #{actual_time_in_secs} seconds."

    assert( @path && !@path.empty?)
    # GC.start
  end
end

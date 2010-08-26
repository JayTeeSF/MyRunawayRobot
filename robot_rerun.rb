require 'test/unit'

require './lib/robot.rb'

class RobotTest < Test::Unit::TestCase

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
      config[level.to_s] = @base_config.dup
      config[level.to_s].merge!(eval(conf_line.chomp))
      print "."
    end    
  rescue EOFError
    puts "!"
  ensure
    conf_file.close
    return config # apparently return(s) must be explicit from an ensure block...
  end

  def test_all_levels
    @config.keys.each do |level|
      try level
    end
  end

  def try level
    @robot = Robot.new @config[level].merge(:debug => false)

    puts "\n\nstarting level #{level}..."
    assert_nothing_raised { @path = @robot.solve }
    assert( @path && !@path.empty?)
  end
end
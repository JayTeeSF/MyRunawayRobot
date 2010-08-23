require 'test/unit'
require './lib/map.rb'
require 'rubygems'
require 'ruby-debug'

class MapTest < Test::Unit::TestCase

  # NOTE: though automated testing of regx's is appropriate
  # I manually used rubular.com to test my regx's <-- because I do not
  # anticipate needing to change this code -- after today


  def setup
    @base_config =  { :ins_min => 1, :ins_max => 1,
                            :terrain_string => ".XX.",
                            :debug => true,
                            :board_x => 2, :board_y => 2,
                            :only_config => true, :cache_off => true
                          }


    @med_mix_config = @base_config.merge({:ins_max => 5, :board_x => 5, :board_y => 5, :terrain_string => ".XXXX..XXXX.XXXX..XXXX.XX"})
    @broken_config3 = @base_config.merge({ :terrain_string =>
	"..................X.....XXX...X....X...XX.X.......XXX...X...X......X.........X.X.X....XX.....X.X....X...XXX.X...X.....X......XX..............X...X.....X........X..XX......X....X.X....X......XX.XX..XX....X.............X..........X...X...X...X............X.XX.X.X.....X.X..X.X.X...X.X..X.X.XX..X...X...X...X...........X..X...X.X....X...X...X...XX.........X..X.X.XX...............X........XX..X....X....XXX...X.........X.......X...XX.XX..XX...X........X....X.....XXX......X...X.X.......X...........XXX..X.X..XXX...X.X.X.X.X.X.............X...X......XX...X..X.X.X...X........X..X....XX......X...X......XX.......X........XX.....X.....X....X.X....X....X...X.X.X...XX......X.............X.....X....X...X...........X....XX......XX....X...........X...X................X...X.....X.............X.X....X............X.......X.X....X.....XX...XXX..XX...X......X...XX............X..........X...XXX...X.....X.....X.......X.X...............X...X......X......XX..........X..X..X...X.......X....X........X..X.X....X.X.X.....X..X.X.X.XXX.X........XX.....X.....X.......X....X..X....XXX.X...X.X.......X..........................X.X......X.....X......X........XXX.............X...X..X.....X..X.XX.....X...X.....X..X....X.X...........X.X.X......X...X.........X..X.XX....X...X...X.............X....X.X...X.X.....XX...........XXX..........XX..X.X..X....X..XX...XX.................X..X.X..XXX.XX...XXX................XX..X.X.......X.......X.X.XX..........X.......X..X.....X..X....X..X.....X.X..X..XX.X..XX.....XX.XXX.................X......X................X.X...X......XX...X......................XX.....X...X...X.......XX.......XX.......XX...............X............X...X..........X..XX.........X.X.X.....................X.......X.X.X..XXX.....X..........XXX....X....X.....XX.X...XXX.....X..............X.XX........X.XX...................X.........X..X........X.XXX...X..XXX.....XXX.......X.....XXX...X..XX.X.XX.X.X...X.....XX...X.XXX.XX.X........X..X...X....X.......XXX.....X....X..X..X........X..X....XX........X......X......XX....X....X...XX.........X.X..X...............X.X...X.................XX..X..X..XX.XXX.X..........................X....X..X.X.........XX.............X.......XXX..X....XXX....X........X....X...X..........XX...X...X.........X...X........XX....XX.................X..XX....X..X.....X...........X.X...X..X...X....XX....X....X.X...X..X.X.XX.X.................X..X.....X..XXX..X...........X....X...XX.X..X..............X..X..X.......X....X..X..X.X...........X.X.......X..XX..XX..X....X.X..X.........X..X......X...XXX.X.XX......X.X........XX....X..X...XX.XX...........XX.X......................X......X....XXXX....XX...X....X.....XX...X.XX.XX...........XX..XX....XX...X.....X.X..X...........X...X....XX.....X..X.....X....X..............XX.X...X......X...XXX.XX..................X.XX.....X..X..X.X............X.X...X...................XXX......X.......X...XX....X.X.XX..X.X..X.........X.........X...X......XX.....X...X...XX............X..X.....X.X.....XXX............XXX.......X....XX...X..........X.......XX.......X.X...XX....X.X.X......X..........XX.XX.........XX.X......X...X..X......X...X....X..X.X..XX.......X.......X.................X.X...X.....X.......X....X.....X...X..................X.XX.X..X....X.............X..XX..X.......XX....XX...X.....XX.X...XXX...X..........X...........X...X.......X.X..X..X...X...X.X.X......X....X...X..X............X.X..X.X.X..X...X...X.X.....X..........XX....X.............XX........X.X.X.XX......X..X..X......X..X...X...X.X...X....X.X...XXX..X....",
	:ins_max=>34, :ins_min=>20, :board_x=>59, :board_y=>59 })
    @super_hard_config = @base_config.merge({ :debug => false, :terrain_string => "...X.X.......XXX..XX.......X.X..X.X.XX......X.X.X..........XX.X..XX.X..X..X.XX.....XX.X..X......X.XX...X.....XX...X..X..XX..X..XX.................X........X..X.........X..X.X.X....X.XXX.X.XX.X.X....XX..X.....X......X...X..X......X......X.X..X..X...X...XXX..X..X.X..X........X.........X.X.........X...X.XXXX....XX.......X....X..X.....X..X.XXX...XX.....X.....XX.XX..X.X.X....X.........X..XX..X...X.X.XX.......X........X......XX........X..X..X......X.X.....X..XXXX..X.X..X.X....XX.XXX.X...X..X.............XX..X.......X...X....XX.X.XXX....X.......X.....X.X....X....X...X..........X........X....XX........X..........X...X.X.X....XX...X.....XXX................X.X....XX....X....X....X.....X.X..XX.X...XXXXX....XX.X...X..X.....X................X.XX.X....XXXXXX....X.......XX...X..X...XX..X..X.....X.X..X...X....X.X......X....X.................X...XX..X......X.X.....XX...XX.X........X...X.XXX....X.......XXX..X.....XX..X....X.....XX.X..X..X...X.XXX..XXX...XX.....X..XX..X.X.....X..X...XX.......X.X..XXX.X..X..XX....X...X..X..XX.....XX......X...X...X.....X.X.........XXX.X.....X...........X...X...XX...........X.......X.....XX......XX...X..X.X...X.X....X..XXX.........XX....XX.XX..................X.XX.....X..XX.........XXXX.......X.XX...X...X.X.X.........X..X..XX..X...X..X...X.X.X.......X.X.XXX.X........X......X..XXX.....X...X...X...X..X.....X....X..........XX....X..XX....XXX...X....XX..X.X..X.....X.......X..X.....X..XX.X......X.....X......X...X.X..XX.....XX...X...XX...X.X......X.X....X...X.......XXX.X.X......X.....XX.XX...X.X....X....X.X.X.......X...X...X.X.....XX.....X...........XX.....XX.X......X...X....XX..X.......X....X....X....XX..X.....X..XX.X.X...X..X.X.XX.X......XX...XXX.X......XXX..X...X...X........X....XX.X......X.X.X..X....X....X......X.X.X..........X.X...X.....X...XX.........XX..XX.X..X....X....X......X....X..X.......XX..X.X..XX..........X....X......XX........X...X...X.X.X.XX.....X...X.X..X.....X..X..X...........X.X...X.......X...XXX...XX.X.......X....X...X.X.X.XXX..X...X.X...X....X.X..X..X..XXX.X...........X.X......X..XX..X.XX......X...X..X.X.....XX.....XX..X.X....XX....X.X....X..............X.X.X.X....X.............X........X..XXX......XX..X....X...X......X.XX...........X....X...X.X..X....XXX..X..X.X..............X.X...X.XXXX......X.X.......XX.X..XX.X..X.XX....X.X...XXX..X............X...X.XX.X.X....................XX.X...X..X...X..X.....X......XXX.X....X.X.X...X....X........X.............XX..X.X....XX.X.X.........X.X.........X.........X...X.XX......X..XXX.X.X.X....XX.......X.....XXXXX.X....XX....XX....X..X...X...XX.X.............XX.....X.X......X.X..X.......X..XX........XX.X..XX..X..X...X.........X..X........X.......X...X.......X..X....X.XXX....X......X...XX........X.XX.....X......X.........X.X.XXXXX.....X..X.......X.X......X..X..X...X..X..X.....XX.....X...X..X........", :ins_max => 31, :ins_min => 18, :board_x => 53, :board_y => 53 })
  end

  def test_draw_maps   
    %w[ base_config med_mix_config ].each do |config|
      ivar = instance_variable_get("@#{config}")
      @map = Map.new ivar
      assert_nothing_raised { @map.config ivar }

      puts "\n#{config} map:"
      @map.draw_matrix
      puts "\n\n"
    end
  end

end

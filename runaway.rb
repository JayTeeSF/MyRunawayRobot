require 'lib/robot'
require 'yaml'
# http://www.hacker.org/runaway/index.php
require 'net/http'
res = nil
path = false
USERNAME = 'jaytee'
print "#{USERNAME}, please enter your password: "
system "stty -echo"
PASSWORD = gets.chomp
puts ""
system "stty echo"
DEFAULT_LEVEL = 0
print "Please enter a start-level [#{DEFAULT_LEVEL}]: "
counter = (gets.chomp || DEFAULT_LEVEL).to_i
puts ""

def get_time
  Time.now
end
alias end_time get_time

start_time = get_time
robot = Robot.new()

def request(append='')
    host = 'www.hacker.org'
    base_request = "/runaway/index.php?name=#{USERNAME}&password=#{PASSWORD}"
    get_request = base_request + append
    puts "getting: #{host}#{get_request}..."
    res = Net::HTTP.get host, get_request
    #case res
    #when Net::HTTPSuccess, Net::HTTPRedirection
      puts "got it.\n"
    #else
    #  puts "error.\n"
    #end
    return res
    #url = URI.parse("http://#{host}")
    #res = Net::HTTP.start(url.host, url.port) {|http|
    #  http.get(get_request)
    #}
    #return res.body
end

while true
  #get_request = base_request "#{path ?  %Q|&path=#{path}| : %Q|&gotolevel=#{counter}|}"
  res = nil
  if path
    res = request(%Q|&path=#{path}|)
    if res[/boom at (\d) (\d)<br>your solution sucked<br>/]
      puts "solution sucked at: #{$1}, #{$2}"
      break
    end
  else
    res = request(%Q|&gotolevel=#{counter}|)
  end
    

  # <PARAM NAME=FlashVars VALUE="FVterrainString=..X...X..&FVinsMax=2&FVinsMin=2&FVboardX=3&FVboardY=3&FVlevel=0">
  #<PARAM NAME=FlashVars VALUE="FVterrainString=..X...X..&FVinsMax=2&FVinsMin=2&FVboardX=3&FVboardY=3&FVlevel=1">

  #puts "response: #{res.inspect}"
  param_name = res[/<PARAM NAME=(.*)>/,1]
  #puts "param_name: #{param_name.inspect}..."
  @params = {
    :terrain_string => param_name[/FVterrainString=([.|X]*)&/,1],
    :ins_max        => param_name[/FVinsMax=(\d*)&/,1].to_i,
    :ins_min        => param_name[/FVinsMin=(\d*)&/,1].to_i,
    :board_x        => param_name[/FVboardX=(\d*)&/,1].to_i,
    :board_y        => param_name[/FVboardY=(\d*)&/,1].to_i,
    :level          => param_name[/FVlevel=(\d*)/,1].to_i
  }
  puts "using: #{@params.map {|k,v| ":#{k} => \"#{v}\""}.join(', ')}...\n"
  robot.instruct(@params)

  path=robot.path
  report = "#{counter.to_s.rjust(3)}"+"[#{@params[:board_x]},#{@params[:board_y]}]".rjust(16) + 
        "(#{@params[:ins_min]}..#{@params[:ins_max]})".center(15) + 
        path.rjust(30) + "  " + (end_time - start_time).to_s
  puts report
  counter += 1
end

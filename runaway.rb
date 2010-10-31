#!/usr/bin/env ruby
#require './lib/robot.rb' #<-- for 1.9.2
require 'lib/robot.rb' #<-- for rbx
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
tries = 3
print "Please enter a start-level [#{DEFAULT_LEVEL}]: "
counter = (gets.chomp || DEFAULT_LEVEL).to_i
puts "\n"

def get_time
  Time.now
end
alias end_time get_time

start_time = get_time

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
  else
    res = request(%Q|&gotolevel=#{counter}|)
  end
  puts "checking reponse..."
  if /you can\'t go to (\d+)\, only to (\d+)\!|boom at (\d+) (\d+)<br>your solution sucked<br>/.match(res.inspect.to_s)
    puts "solution sucked at: #{$1}, #{$2}"
    puts "bogus response was: #{res.to_s}"
    exit
  else
    puts "ok\n\n"
  end
    

  # <PARAM NAME=FlashVars VALUE="FVterrainString=..X...X..&FVinsMax=2&FVinsMin=2&FVboardX=3&FVboardY=3&FVlevel=0">
  #<PARAM NAME=FlashVars VALUE="FVterrainString=..X...X..&FVinsMax=2&FVinsMin=2&FVboardX=3&FVboardY=3&FVlevel=1">

  param_name = res[/<PARAM NAME=(.*)>/,1]
  #puts "param_name: #{param_name.inspect}..."
  if param_name.nil?
    puts "bogus param_name from response: #{res.to_s}"
    attempt = 1
    while attempt <= tries
      sleep 20
      res = request(%Q|&gotolevel=#{counter}|)
      param_name = res[/<PARAM NAME=(.*)>/,1]
      if param_name || /you can\'t go to (\d+)\, only to (\d+)\!|boom at (\d+) (\d+)<br>your solution sucked<br>/.match(res.inspect.to_s)
        puts "response: #{res.inspect}"
        break
      else
        puts "bogus param_name from response: #{res.inspect}"
        attempt += 1
      end
    end
  end
  if param_name.nil?
    puts "failed to get a valid response...\n"
    exit
  end

  @params = {
    :terrain_string => param_name[/FVterrainString=([.|X]*)&/,1],
    :ins_max        => param_name[/FVinsMax=(\d*)&/,1].to_i,
    :ins_min        => param_name[/FVinsMin=(\d*)&/,1].to_i,
    :board_x        => param_name[/FVboardX=(\d*)&/,1].to_i,
    :board_y        => param_name[/FVboardY=(\d*)&/,1].to_i,
    :level          => param_name[/FVlevel=(\d*)/,1].to_i
  }
  puts "\n\nusing: #{@params.map {|k,v| ":#{k} => \"#{v}\""}.join(', ')}...\n"
  robot ||= Robot.new()
  # GC.start
  robot.instruct(@params)

  path=robot.path
  report = "#{counter.to_s.rjust(3)}"+"[#{@params[:board_x]},#{@params[:board_y]}]".rjust(16) + 
        "(#{@params[:ins_min]}..#{@params[:ins_max]})".center(15) + " p>" +
        path.rjust(30) + "<  " + (end_time - start_time).to_s
  puts report
  unless (path || path.size > 0)
    puts "no path...; get a fresh board"
    counter += 1
  end
end

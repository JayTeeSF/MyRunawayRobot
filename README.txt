NEW INSIGHT: min = 18, max = 31; diff=13; double_min = 36; double_max=62; THUS double_min + diff is only 49 need double_diff (26) + double_min = 62
New algorithm:
  decouple robot and map
  runaway should instantiate map, and then pass-it to the robot (via the queue?!)
  poll for Robot.path
   # which internally queries Level:<level>:Path => xxxx

  Robot accesses self.map(:method => x)
  Robot#map does @map ||= a call to Map.find(level)
     Map instantiates finder that calls Redis and unmarshalls the map for lvl -- unless current-level has changed...



  Use Resque (or just Redis)

  key(s) => value(s):
  CurrentLevel =>  <lvl>
  Level:<level>:Init => <optionsHash>
  Level:<level>:Map => <marshalledMapObject>
  Level:<level>:Robot => <marshalledRobotObject>

  StartJob(s) go in Queue ...we need a special type of "job" that defines this level's details
    that way many "robot"-workers and "map"-workers can get their initialization
    perhaps we just serialize a robot and/or a map
    then any agent (running on any machine) can unmarshall a robot or a map, and start processing
    the incoming request...

  RobotControl needs to initialize everybody (?perhaps?)
  RobotControl would look for the result of Map-workers -- if ever a result, publish LevelNComplete
  (possibly clean-up old level)

  Robot-workers place MapVerify Jobs in Queue (for Map-workers)
    Robot-workers continue processing -- under the assumption that Map-workers would return false

  Concerns:
    Map-workers should be able to pull (randomly) from the "Queue"
    Map-initializer (for the current-level) ought to supply the canonical "map" for any workers that spawn-up

  The recursive Robot, will place potential solutions in that Queue
  

# jruby - no support for fork yet...
# -J-Djruby.fork.enabled=true 
# perhaps I should use "threads!"
# ruby --server --fast -J-Djruby.compile.fastest=true -J-Djruby.jit.threshold=100 -J-Djruby.jit.max=8192 -J-Djruby.thread.pool.enabled=true ./robot_long_performance.rb

# nah:
ruby --server --fast -J-Djruby.compile.fastest=true -J-Djruby.jit.threshold=100 -J-Djruby.jit.max=8192 ./robot_rerun.rb -n test_105


using rubinius one speed-up involves the JIT:

the default is to set the counter to 4000, but 4250 yields better results (4500 was slower, as was 3500)
ruby -Xjit.call_til_compile=4250 ./robot_long_performance.rb

# add the print option, to see other tuning-params:
ruby -Xconfig.print -Xjit.call_til_compile=4250 ./robot_long_performance.rb


ruby -Xjit.call_til_compile=4250 ./robot_rerun.rb -n test_all_levels


# too much gc, goin' on:
ruby -Xprofile=true -Xinterpreter.dynamic=true -Xgc.show=true ./robot_rerun.rb -n test_105

defaults (ruby -Xconfig.print):
	gc.bytes: 3145728
	gc.large_object: 2700
	gc.lifetime: 3
	gc.autotune: true
	gc.show: false
	gc.immix.debug: false
gc.honor_start: false
	gc.autopack: true

ruby -Xinterpreter.dynamic=true -Xgc.honor_start=true -Xgc.show=true ./robot_rerun.rb -n test_105

# multi-threads:
#  rubinius
#  ruby -Xjit.call_til_compile=4096 ./robot_long_performance.rb
#  jruby
# ruby --server -J-Djruby.jit.threshold=100 -J-Djruby.jit.max=8192 -J-Djruby.thread.pool.enabled=true ./robot_long_performance.rb

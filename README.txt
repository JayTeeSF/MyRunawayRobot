using rubinius one speed-up involves the JIT:

the default is to set the counter to 4000, but 4250 yields better results (4500 was slower, as was 3500)
ruby -Xjit.call_til_compile=4250 ./robot_long_performance.rb

# add the print option, to see other tuning-params:
ruby -Xconfig.print -Xjit.call_til_compile=4250 ./robot_long_performance.rb


ruby -Xjit.call_til_compile=4250 ./robot_rerun.rb -n test_all_levels

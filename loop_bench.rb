#!/usr/bin/env ruby
require 'benchmark'

range_test = Benchmark.measure do
  10_000_000.times do
    (0..5).each do |i| i end
  end
end.total

upto_test = Benchmark.measure do
  10_000_000.times do
    (0).upto(5) do |i| i end
  end
end.total

puts "Range: " + range_test.to_s
puts "Upto: " + upto_test.to_s
puts



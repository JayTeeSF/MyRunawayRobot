class Hmmr
def dec2bin(decimal)
	str = ""
	(0..(decimal.size - 1)).each {|slot| str += (decimal[slot]||0).to_s }
	return str
end

start_time = Time.now
h = Hmmr.new

#puts h.dec2bin(8)
(0..8000).each do |decimal|
	bin = h.dec2bin(decimal).reverse
	puts "dec: #{decimal} => binary:>>#{bin}<<"
end

finish_time = Time.now
puts "took: #{finish_time - start_time} seconds"
end

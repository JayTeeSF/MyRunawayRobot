class GenBin
  def self.doIt(base_ten,num_digits)
    binary_ary = (num_digits-1).downto(0).map {|slot| base_ten[slot] || 0}
    binary = binary_ary.join
    puts "#{base_ten} (base_ten) as #{num_digits} digit binary => #{binary}"
  end
end
#g = GenBin.doIt(ARGV[0],ARGV[1])

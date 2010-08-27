# bf = BitFieldC.new
# bf.getbit(0b101.to_s,0) # => 1 
# bf.getbit(0b101.to_s,1) # => 0 
# bf.getbit(0b101.to_s,2) # => 1 

require 'rubygems'
require 'inline'
class BitFieldC

  inline(:C) do |builder|
    builder.c "char *setbit(char *z, int position) {
      z[position/8] |= (1<<(position%8));
      return z;
    }"

    builder.c "char *unsetbit(char *z, int position) {
      z[position/8] ^= (1<<(position%8));
      return z;
    }"
    
    builder.c "int getbit(char *z, int position) {
      if (z[position/8] & (1<<(position%8)))
        return 1;
      return 0;
    }"
  end

end

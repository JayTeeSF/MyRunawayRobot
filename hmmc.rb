require 'rubygems'
require 'inline'

#for more advanced 1.8 / 1.9 support, see:
#http://tenderlovemaking.com/2009/06/26/string-encoding-in-ruby-1-9-c-extensions/

class Hmmc
	inline do |builder|
		builder.include '<stdio.h>'
		builder.include '<string.h>'
foo = <<'YOOO'
static VALUE dec2bin(int i, char *str) {
	//63:
	//char str[] = "000000000000000000000000000000000000000000000000000000000000000";
	//char str[] = "0000000000000";
	char* p;
	p = str;
	while (i>0) {
		/* bitwise AND operation with the last bit */
		(i & 0x1) ? (*p++='1') : (*p++='0');
		/* big shift right */
		i >>= 1;
	}
	//print bkwds
	return rb_str_new2(str);
}
YOOO
		builder.c foo
	end
end

start_time= Time.now
h= Hmmc.new()

str = "";
#000000000000000000000000000000000000000000000000000000000000000";
(0..8000).each do |decimal|
	bin = h.dec2bin(decimal,str).reverse
	puts "dec: #{decimal} => binary:>>#{bin}<<"
end

finish_time = Time.now
puts "took: #{finish_time - start_time} seconds."

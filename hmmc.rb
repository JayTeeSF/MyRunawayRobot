require 'rubygems'
require 'inline'

#for more advanced 1.8 / 1.9 support, see:
#http://tenderlovemaking.com/2009/06/26/string-encoding-in-ruby-1-9-c-extensions/
#define RARRAYPTR(v) RARRAY(v)->ptr

class Hmmc
	inline(:C) do |builder|
		builder.include '<stdio.h>'
		builder.include '<string.h>'
		builder.include '<sys/types.h>'
foo = <<-'YOOO'
static VALUE get_binaries(int min, int max, int max_height, int max_width, VALUE matrix) {
  char* str;
  char* p;
  int c, x, y, j, i;
  int cell_val, curr_len, count,  num_zeros, how_big;
  int path_len, mutable_base_ten, base_ten, max_base_ten;
  VALUE arr = rb_ary_new();

  for (path_len=min; path_len<=max; path_len++) {
    max_base_ten = ((1 << path_len) - 1);
    for (base_ten=0; base_ten<= max_base_ten; base_ten++) {
      mutable_base_ten = base_ten;
      //str = malloc( sizeof(long)*8*sizeof(char) );
      how_big = ( sizeof(int)*path_len*sizeof(char) );
      //printf("mallocing a str that is %d bytes\n",how_big);
      str = malloc( how_big );
      p = str;

      curr_len = 0;
      // convert int to binary:
      while (mutable_base_ten>0) {
        curr_len++;
        //printf("mutating bten: %d\n",mutable_base_ten);
        /* bitwise AND operation with the last bit */
        (mutable_base_ten & 0x1) ? (*p++='1') : (*p++='0');
        /* big shift right */
        mutable_base_ten >>= 1;
      }
      if (0 == base_ten) {
        curr_len++;
        (*p++='0');
      }

      num_zeros = 0;
      printf("path_len(%d) vs. curr_len(%d)\n",path_len,curr_len);
      if (path_len > curr_len) {
        num_zeros = path_len - curr_len;
        printf("appending %d 0's to str\n",num_zeros);
      }
      for (i = 0; i < num_zeros; i++) {
        curr_len++;
        (*p++='0');
      }
      //printf("done mutating bten: %d\n",mutable_base_ten);

      // reset p to beginning of str:
      p = str;

      //reverse:
      for (x=0, j=strlen(p)-1; x<j; x++, j--)
        c = p[x], p[x] = p[j], p[j] = c;

        printf("base_ten(%d) resulted in str (%s) of len: %d\n",base_ten,str,curr_len);

        //verify path, convert-it to a ruby-array and return
        //OR
        //loop to the next num...

        //init robot-location:
        x = 0, y = 0;

        //move-robot, till we crash or succeed
        count = 0;
        while ((y < (max_height-1)) && (x < (max_width -1))) {
          if (0 == (count % curr_len) ) {
            // reset p to beginning of str:
            p = str;
          }
          count++;
          if ('0' == *p) {
            printf("p is 0\n");
            y++;
          } else if ('1' == *p) {
            printf("p is 1\n");
            x++;
          } else {
            printf("got a bogus p value\n");
          }
          p++;

          cell_val = NUM2INT(RARRAY_PTR(RARRAY_PTR(matrix)[y])[x]);
          printf("cell_val at y(%d),x(%d): %d\n",y,x,cell_val);
          //cell_val = RARRAY(RARRAY(matrix)->ptr[y])->ptr[x]
          if (0 == cell_val) {
            // crash
            printf("crash...\n");
            break;
          } else if (2 == cell_val) {
            // success
            rb_ary_push(arr, rb_str_new2(str));
            printf("success; freeing str...\n");
            free(str);
            return arr;
          }
        }

        printf("freeing str...\n");
        free(str);
      }
    }

	// if we got here, then we return an empty array
	return arr;
}
YOOO
		builder.c foo
	end
end

start_time= Time.now
h= Hmmc.new()

#str = "";
#(0..8000).each do |decimal|
#	puts "dec: #{decimal} => binary:>>#{bin}<<"
	#path = h.solve(decimal)
#end
matrix = [[1,1,2],[0,1,2],[2,2,2]]
# call get_binaries in multiple threads ...perhaps one per (min..max).each
# check the results of each thread to see if it's a non-empty array
# as soon as one returns successful, use its result &  kill any other threads
puts "using mh: #{matrix.size} and mw: #{matrix[0].size} w/ m:  #{matrix}"
myary = h.get_binaries(2,2,matrix.size,matrix[0].size, matrix)
puts "got: #{myary.inspect}"

finish_time = Time.now
puts "took: #{finish_time - start_time} seconds."

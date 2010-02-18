require 'rubygems'
require 'inline'
require 'drb'

class RobotService
  attr_accessor :map, :path, :min, :max, :start_x, :start_y, :debug, :matrix,
  :right_till_bomb, :down_till_bomb, :instruct_options

  def echo(param="got nut'in")
    puts "echo got: #{param}"
    return param
  end

  def r_get_binaries(min, max, max_height, max_width, matrix, first_bomb_right, first_bomb_down, debug)
    puts "calling: get_binaries(#{min},#{max},#{max_height},#{max_width},#{matrix},#{first_bomb_right},#{first_bomb_down}, #{debug})"
    got = get_binaries(min,max,max_height,max_width,matrix,first_bomb_right,first_bomb_down, debug)
    puts "got: #{got}"
    return got
  end

	inline(:C) do |builder|
		builder.include '<stdio.h>'
		builder.include '<string.h>'
		builder.include '<sys/types.h>'
foo = <<-'YOOO'

static VALUE get_binaries(int min, int max, int max_height, int max_width, VALUE matrix, int first_bomb_right, int first_bomb_down, int debug) {

  //printf("starting\n");
  //printf("range: %d - %d\n",min, max);

  // http://www.exforsys.com/tutorials/c-language/c-arrays.html
  //int matrix[#{height}][#{width}]={{0,0,0},{1,1,1}};

  //VALUE rstr = rb_str_new2("");
  char* str;
  char* p;
  int c, x, y, j, i;
  int cell_val, curr_len, count,  num_zeroes;
  unsigned int valid_bomb_down, valid_bomb_right, close_bomb_down, close_bomb_right;
  int how_big = ( sizeof(int)*sizeof(char) );
  int path_len, mutable_base_ten, base_ten, max_base_ten;
  VALUE arr = rb_ary_new();
  //int palindrome, tmp_int;
  // ID method = rb_intern("draw_matrix");

  //printf("initialized...\n");
/*
  if (debug == 1) {
    if (! rb_respond_to(self, rb_intern("draw_matrix")))
      rb_raise(rb_eRuntimeError, "target must respond to 'draw_matrix'");
  }
*/
  // before any loops...
  valid_bomb_right = 0;
  close_bomb_right = 0;
  if (first_bomb_right < max_width) {
    if (first_bomb_right < 3) {
      close_bomb_right = 1;
    }
    valid_bomb_right = 1;
  }

  valid_bomb_down = 0;
  close_bomb_down = 1;
  if (first_bomb_down < max_height) {
    if (first_bomb_down <= 3) {
      close_bomb_down = 0;
    }
    valid_bomb_down = 1;
    //close_bomb_down = 1;
  }

// the following two macros only work for A's between 2 & 9
//#define num_digits(A) (A < 3) ? 2 : ((A < 8) ? 3 : 4)
//#define last_digit_count(A) ((7 == A) || (8 == A)) ? 3 : (((3 == A)||(4 == A)) ? 2 : 1)

  //printf("binary-lengths ranging from %d - %d\n",min,max);
printf("ready to loop...\n");
  for (path_len=min; path_len<=max; path_len++) {
    max_base_ten = ((1 << path_len) - 1);
    printf("length %d: binary-nums ranging from 0 - %d\n",path_len, max_base_ten);
    for (base_ten=0; base_ten<= max_base_ten; base_ten++) {
      // skip 000... or 111... if we have a valid down/right bomb
//(8 == base_ten && (first_bomb_down < path_len))
//(base_ten == 3 || base_ten == 7 || base_ten == max_base_ten)
	  // (respectively)
      if ( (1 == valid_bomb_down && 0 == base_ten ) || (1 == valid_bomb_right && base_ten == max_base_ten)) {
       //printf("skipping explosing before generating string...\n");
        continue;
      }
      //if ((1 == valid_bomb_down) && ((4 == base_ten) || (8 == base_ten)) && (first_bomb_down < path_len)  ) {
        //even = ( (0 == (base_ten % 2)) ? 1 : 0 );
        // odd base_tens end w/ 1
        //if ( (1 == close_bomb_right) && (0 == even) && ((last_digit_count(base_ten)) >= first_bomb_right)) { 
          //continue;
        //} else if ((1 == valid_bomb_down) && (1 == even) 
          //&& (((last_digit_count(base_ten)) + (path_len - (num_digits(base_ten)))) >= first_bomb_down)) {
        //}
      //}
      mutable_base_ten = base_ten;
      //str = malloc( sizeof(long)*8*sizeof(char) );
      //how_many = ( sizeof(int)*path_len*sizeof(char) );
      //how_big = ( sizeof(int)*path_len*sizeof(char) );
      // //printf("mallocing a str that is %d bytes\n",how_big);
      str = calloc( path_len + 1, how_big );
	  // need to reset this to blank...
  //str = RSTRING_PTR(rstr);
      // *str = '\0';
      p = str;

      curr_len = 0;
      // convert int to binary:
      while (mutable_base_ten>0) {
        curr_len++;
        // //printf("mutating bten: %d\n",mutable_base_ten);
        /* bitwise AND operation with the last bit */
        (mutable_base_ten & 0x1) ? (*p++='1') : (*p++='0');
        /* big shift right */
        mutable_base_ten >>= 1;
      }
      // //printf("done mutating bten: %d\n",mutable_base_ten);

      //printf("path_len(%d) vs. curr_len(%d)\n",path_len,curr_len);
      //append zero's if necessary
      num_zeroes = 0;
      if (path_len > curr_len) {
        num_zeroes = (path_len - curr_len);
        if ( (num_zeroes > 3) && (0 == close_bomb_down) ) {
          continue;
        }
      }
      //printf("appending %d 0's to str(%s)\n",num_zeroes,str);
      for (i = 0; i < num_zeroes; i++) {
        curr_len++;
        (*p++='0');
      }

      // reset p to beginning of str:
      p = str;


      //reverse:
      for (x=0, j=strlen(p)-1; x<j; x++, j--)
        c = p[x], p[x] = p[j], p[j] = c;

      //printf("%d (base_ten) => %s (%d digit binary)\n",base_ten,str,curr_len);

        //printf("base_ten(%d) resulted in str (%s) of len: %d\n",base_ten,str,curr_len);

        //verify path, convert-it to a ruby-array and return
        //OR
        //loop to the next num...

        //init robot-location:
        x = 0, y = 0;

        //move-robot, till we crash or succeed
/*
        if (debug == 1) {
          printf("\n-- bgn initial map --\n");
          rb_funcall(self, rb_intern("draw_matrix"), 2, INT2FIX(y), INT2FIX(x));
          printf("-- end initial map --\n\n");
        }
*/
        count = 0;
        while ( (y < max_height) && (x < max_width) ) {
          if (0 == (count % curr_len) ) {
            // starting a cycle-through this binary #
            // reset p to beginning of str:
            p = str;
          }
          count++;
          if ('0' == *p) {
            //printf("p is 0\n");
            y++;
          } else if ('1' == *p) {
            //printf("p is 1\n");
            x++;
          } else {
            printf("got a bogus p value\n");
          }
          p++;

          cell_val = NUM2INT(RARRAY_PTR(RARRAY_PTR(matrix)[y])[x]);
          //printf("cell_val at y(%d),x(%d): %d\n",y,x,cell_val);
          //cell_val = RARRAY(RARRAY(matrix)->ptr[y])->ptr[x]
/*
          if (debug == 1) {
            rb_funcall(self, rb_intern("draw_matrix"), 2, INT2FIX(y), INT2FIX(x));
          }
*/
          if (0 == cell_val) {
            // crash
            if (debug == 1) {
              printf("CRASH... base_ten(%d) resulted in str (%s) of len: %d (suppose to be: %d)\n",base_ten,str,curr_len,path_len);
            }
            break;
          } else if (2 == cell_val) {
            // success
            rb_ary_push(arr, rb_str_new2(str));
            //if (debug == 1) {
              printf("MADE-IT... base_ten(%d) resulted in str (%s) of len: %d (suppose to be: %d)\n",base_ten,str,curr_len,path_len);
            //rb_funcall(self, rb_intern("draw_matrix"), 2, INT2FIX(y), INT2FIX(x));
            //}
            free(str);
            return arr;
          }
        }
		free(str);
      }
    }

    //free(str);
	// if we got here, then we return an empty array
	printf("returning\n");
	return arr;
}
YOOO
		builder.c foo
	end

end
require 'socket'
ip = IPSocket.getaddress(Socket.gethostname) || '127.0.0.1'
port =  ARGV[0] || '61676'
puts "port: #{port}"
puts "ip: #{ip}"
puts "pid: #{$$}"
DRb.start_service("druby://#{ip}:#{port}", RobotService.new)
DRb.thread.join

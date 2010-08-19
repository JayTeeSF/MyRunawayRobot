require 'rubygems'
require 'inline'
# require 'thread'  # For Mutex class in Ruby 1.8
require 'lib/map.rb'
class Robot

  attr_accessor :map, :path, :min, :max, :start_x, :start_y, :debug, :matrix,
  :right_till_bomb, :down_till_bomb

  #
  # this method gives the robots its marching orders
  # by default it will trigger the robot to "solve" the puzzle
  # (primarily because that's the API defined by runaway.rb)
  # options include:
  # :only_config  #<-- do not solve
  #
  def instruct(params={})
    puts "params: #{params.inspect}" if @debug
    options = {
      :board_x => 1,
      :board_y => 1,
      :ins_min => 0,
      :ins_max => 0
      }.merge(params)

      @start_x = 0
      @start_y = 0
      @cache_off = options[:cache_off]
      @min = options[:ins_min]
      @max = options[:ins_max]
      @map_terrain = options[:terrain_string]
      @map_width = options[:board_x] - 1
      @map_height = options[:board_x] - 1
      clear_path
      @right_till_bomb = 0
      @down_till_bomb = 0

      construct_matrix
      solve() if options[:only_config].nil?
    end

    def initialize(params={})
      @debug = params[:debug]
      @lock = Mutex.new  # For thread safety
      params.delete(:debug)
      instruct(params) if params != {}
    end

    def clear_matrix
      @matrix = []
    end

    # human readable
    def draw_matrix(row=nil,col=nil)
      @lock.synchronize {
        #return unless @debug
        puts "called with row(#{row.inspect}), col(#{col.inspect})"
        construct_matrix unless @matrix
        if (row && col)
          # deep copy the array, before inserting our robot
          matrix = Marshal.load(Marshal.dump(@matrix))
          matrix[row][col] = (matrix[row][col] == Robot.bomb()) ? Robot.boom() : Robot.robot
        else
          matrix = @matrix
        end

        puts "\n#-->"
        matrix.each {|current_row| puts "#{current_row}"}
        puts "#<--\n"
      }
    end

    def construct_matrix
      next_cell = cell_generator
      clear_matrix
      (0..@map_height).each do |y_val|
        matrix_row = []
        (0 .. @map_width).each do |x_val|
          result = ('.' == next_cell.call ? Robot.safe : Robot.bomb )
          matrix_row << result
        end
        matrix_row << Robot.success
        @matrix << matrix_row
      end
      matrix_row = []
      (0 .. (@map_width + 1)).each do |x_val|
        matrix_row[x_val] = Robot.success
      end
      @matrix << matrix_row
    end

    #
    # return a char-by-char terrain iterator
    # :terrain_string=>"..X...X.."
    #
    def cell_generator
      terrain_ary = @map_terrain.gsub(/[^X\.]+/,"").split(//)
      i = -1
      lambda { i += 1; terrain_ary[i] }
    end

    # should make this work from a given coordinate...
    def moves_till_bomb(direction)
      count = 0
      if direction == 'right'
        # /^([\.]+)X/.match(@map_terrain)
        tmp_path = @map_terrain[/^([\.]+)X/,1]
        if tmp_path
          count += tmp_path.size
        else
          count = @map_terrain.size + 1
        end
      else
        begin
          count += 1
          if count >= @matrix.size
            count = @matrix.size + 1
            break
          end
        end until @matrix[count][0] == Robot.bomb
      end
      return count
    end

    def self.bomb
      0
    end

    def self.safe
      1
    end

    def self.boom
      6
    end

    def self.robot
      8
    end

    def self.success
      2
    end

    def self.down
      'D'
    end

    def self.right
      'R'
    end

    def clear_path
      @path = []
    end

    def solve(current_path=[])
      
      if current_path.size >= @min
        if current_path.size > @max
          return false # need to force code to undo last move and try another option
        else
          if verify current_path
            puts "Found it (#{current_path.inspect})!"
            return current_path
          end
        end            
      end
      
      row, col = *map.left_off(current_path)
      if map.avail(Robot.down(), row,col)
        current_path << Robot.down()
        if ! solve(current_path)
          current_path.pop
          map.undo!(Robot.down(), row,col)
        else
          return current_path
        end
      end
      
      if map.avail(Robot.right(), row,col)
        current_path << Robot.right()
        if ! solve(current_path)
          current_path.pop
          map.undo!(Robot.right(), row,col)
        else
          return current_path
        end
      end

    end



    #
    # come-up with a solution to the terrain-map
    # the idea for this method came from thinking about
    # logic truth-tables which spit-out T's & F's
    # to thinking about the CS tables of 1s & 0s
    # and, of course converting binary 1's & 0's
    # to D's & R's is easy
    #
    def old_solve
      use_threads = false
      # given an 'n' between min & max
      # total possible results: 2**n
      # a path can be constructed from binary values ranging from n-0's  .. n-1's
      # thus the values range from 0 - ((2**n)-1)
      # if the array is smaller than 'n', pad it w/ 0's
      # then, merely substitute D's for 0's and R's for 1's (or vice-versa)

      # here's a key piece of Ruby-Fu (did you know base-ten => binary was so
      # easy ?!):
      # (0 .. (n.size)).each { |slot| puts "slot: #{slot}: #{n[slot]}" }

      puts "solving..." if @debug
      next_move = []
      # even_move:
      mid_val = mid()

      # first check if we've already got a solution to this map...
      #count = 0
      #@path = map.lookup_solution(min(),max()) || []
      @path = []

      if [] == @path
        debug_level = 0
        debug_level = 1 if @debug
        palindrome_start = @min * 2;
        thread_ary = []
        #how-many 1's before we see a bomb
        first_bomb_right = moves_till_bomb('right')
        #how-many 0's before we see a bomb
        first_bomb_down = moves_till_bomb('down')
        if use_threads
          if mid_val > @min
            thread_ary[thread_ary.size] = Thread.new { Thread.current["binary_str"] = get_binaries(@min,mid_val,@matrix.size-1,@matrix[0].size-1, @matrix,first_bomb_right,first_bomb_down,debug_level).first }
            if @max > mid_val
              mid_val += 1
            end
          end
          thread_ary[thread_ary.size] = Thread.new { Thread.current["binary_str"] = get_binaries(mid_val,@max,@matrix.size-1,@matrix[0].size-1, @matrix,first_bomb_right,first_bomb_down,debug_level).first }
          while [] == @path && thread_ary.size > 0
            sleep 0.01
            thread_ary.each_with_index do |thr,i|
              if ! thr.status
                thread_ary.delete(i)
                if thr && thr["binary_str"]

                  #got what we wanted
                  @path = binary_to_path( thr["binary_str"].split(//) )
                  path_size = @path.size
                  if path_size > @max
                    tmp_path = @path[(path_size - max)..(path_size - 1)]
                    puts "surgery... trimming #{@path.to_s} => #{tmp_path.to_s}"
                    @path = tmp_path
                  end
                  puts "got path: #{@path}\n";

                  break
                end
              end
            end
          end

          #kill all other threads
          thread_ary.each {|thr| Thread.kill(thr) }
        else
          #former 2-lines:
          binary_str = get_binaries(@min,@max,@matrix.size-1,@matrix[0].size-1, @matrix, first_bomb_right, first_bomb_down, debug_level ).first
          @path = ( binary_str.nil? ) ? [] : binary_to_path( binary_str.split(//) )
        end

        raise RuntimeError, "failed trying'" if [] == @path
        puts "got path: #{@path.inspect}" if @debug
        #idx = move_size > 0 ? count % move_size : 0
        #@path = next_move[idx] ? next_move[idx].call||[] : []
        #count += 1
      else
        puts "found previous solution" #if @debug
        return
      end

      # if we got this far then we were successful
      if @debug
        puts "solved."
      end

      # save this path to our solutions 'cache' file, for future use
      #@map.save(min(),max(),path()) unless @cache_off
    end

    #
    # a string version of the current path-array
    #
    def path
      @path.join
    end

    def mid(min=@min,max=@max)
      diff = max - min
      #return 1 if 0 == diff
      mid = min + (diff / 2)
      puts "mid: #{mid}"
      mid
      #min + ((max - min) / 2)
    end

    #
    # substitute R's & D's for 1's and 0's
    #
    def binary_to_path(binary_ary)
      puts "transforming binary: #{binary_ary.join}..." if @debug
      binary_ary.map {|digit| (digit.to_s == "0")? Robot.down() : Robot.right() }
    end

    # static VALUE get_binaries(int min, int max, int max_height, int max_width, VALUE matrix, VALUE rstr, int debug, int palindrome_start) 

    inline(:C) do |builder|
      builder.include '<stdio.h>'
      builder.include '<string.h>'
      builder.include '<sys/types.h>'
      foo = <<-'YOOO'
      static VALUE get_binaries(int min, int max, int max_height, int max_width,
      VALUE matrix, int first_bomb_right, int first_bomb_down, int debug) {
        //VALUE rstr = rb_str_new2("");
        char* str;
        char* p;
        int c, x, y, j, i;
        int cell_val, curr_len, count,  num_zeros;
        int bomb_down, bomb_right;
        char down_bomb_str[1000], right_bomb_str[1000];
        //int right_cell, left_cell;
        int how_big = ( sizeof(int)*sizeof(char) );
        int path_len, mutable_base_ten, base_ten, max_base_ten;
        VALUE arr = rb_ary_new();
        //int palindrome, tmp_int;
        // ID method = rb_intern("draw_matrix");
        if (! rb_respond_to(self, rb_intern("draw_matrix")))
          rb_raise(rb_eRuntimeError, "target must respond to 'draw_matrix'");

          // // this value should probably be passed-in
          //palindrome_start = min * 2;

          // before any loops...
          bomb_down = 0;
          bomb_right = 0;
          if (first_bomb_right <=3) {
            bomb_right = 1;
            for (i=0; i<=first_bomb_right;i++) {
              right_bomb_str[i] = '1'; // 1 means 'right'
            }
            right_bomb_str[first_bomb_right] = '\0';
            //right_bomb_str[first_bomb_right + 1] = '\0';
            printf("first_bomb_right is %d paces right, using: right_bomb_str(%s)\n",first_bomb_right, right_bomb_str);
          }

          if (first_bomb_down <=5) {
            bomb_down = 1;
            for (i=0; i<=first_bomb_down;i++) {
              down_bomb_str[i] = '0'; // 0 means 'down'
            }
            down_bomb_str[first_bomb_down] = '\0';
            //down_bomb_str[first_bomb_down + 1] = '\0';
            printf("first_bomb_down is %d paces down, using: down_bomb_str(%s)\n",first_bomb_down, down_bomb_str);
          }

          //printf("binary-lengths ranging from %d - %d\n",min,max);
          for (path_len=min; path_len<=max; path_len++) {
            if (path_len < first_bomb_down) {
              bomb_down = 0;
            }
            if (path_len < first_bomb_right) {
              bomb_right = 0;
            }
            max_base_ten = ((1 << path_len) - 1);
            //printf("binary-nums ranging from 0 - %d\n",max_base_ten);
            for (base_ten=0; base_ten<= max_base_ten; base_ten++) {
              if ( ((1 == bomb_down) && (0 == base_ten))
                || ((1 == bomb_right) && (base_ten == max_base_ten))) {
                  //printf("skipping explosing before generating string...\n");
                  //free(str);
                  continue;
                }
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
                if (0 == base_ten) {
                  curr_len++;
                  (*p++='0');
                  } else {
                    while (mutable_base_ten>0) {
                      curr_len++;
                      // //printf("mutating bten: %d\n",mutable_base_ten);
                      /* bitwise AND operation with the last bit */
                      (mutable_base_ten & 0x1) ? (*p++='1') : (*p++='0');
                      /* big shift right */
                      mutable_base_ten >>= 1;
                    }
                  }
                  // //printf("done mutating bten: %d\n",mutable_base_ten);

                  //append zero's if necessary
                  num_zeros = 0;
                  //printf("path_len(%d) vs. curr_len(%d)\n",path_len,curr_len);
                  if (path_len > curr_len) {
                    num_zeros = path_len - curr_len;
                    //printf("appending %d 0's to str(%s)\n",num_zeros,str);
                  }
                  for (i = 0; i < num_zeros; i++) {
                    curr_len++;
                    (*p++='0');
                  }

                  // reset p to beginning of str:
                  p = str;


                  //reverse:
                  for (x=0, j=strlen(p)-1; x<j; x++, j--)
                    c = p[x], p[x] = p[j], p[j] = c;

                    //printf("%d (base_ten) => %s (%d digit binary)\n",base_ten,str,curr_len);

                    // we want to skip any 'str' values that attempt to go through bombs...
                    if ((1 == bomb_down) && (strnstr(str,down_bomb_str,first_bomb_down) != NULL)) {
                      //printf("skipping explosing(%s)...\n",str);
                      free(str);
                      continue;
                    }
                    // if it's too far to the right, then we'll be doing too many checks...
                      if ((1 == bomb_right) && (strnstr(str,right_bomb_str,first_bomb_right) != NULL)) {
                        //printf("skipping explosing(%s)...\n",str);
                        free(str);
                        continue;
                      }
                      /**
                      //once we get to palindrome_start then start checking for palindromes
                      palindrome = 0;
                      if (curr_len > palindrome_start) {
                        // check if it's even
                        tmp_int = curr_len / 2;
                        if ((tmp_int * 2) == curr_len) {
                          palindrome = 1;
                          printf("dealing with an even number of digits; check for palindrome...\n");
                          // break, if the number is a palindrome:
                          p2 = str;
                          p2 += tmp_int;
                          for (i=0; i<tmp_int; i++) {
                            if (*p != *p2) {
                              palindrome = 0;
                              break;
                            }
                            p++,p2++;
                          }
                        }
                      }
                      if (1 == palindrome) {
                        printf("skipping a palindrome(%s)...\n",str);
                        free(str);
                        next;
                      }
                      */
                      //printf("base_ten(%d) resulted in str (%s) of len: %d\n",base_ten,str,curr_len);

                      //verify path, convert-it to a ruby-array and return
                      //OR
                      //loop to the next num...

                      //init robot-location:
                      x = 0, y = 0;

                      //move-robot, till we crash or succeed
                      if (debug >= 1) {
                        printf("\n-- bgn initial map --\n");
                        rb_funcall(self, rb_intern("draw_matrix"), 2, INT2FIX(y), INT2FIX(x));
                        printf("-- end initial map --\n\n");
                      }
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

                            if (debug >= 1) {
                              rb_funcall(self, rb_intern("draw_matrix"), 2, INT2FIX(y), INT2FIX(x));
                            }
                            if (0 == cell_val) {
                              // crash
                              if (debug >= 1) {
                                printf("CRASH... base_ten(%d) resulted in str (%s) of len: %d (suppose to be: %d)\n",base_ten,str,curr_len,path_len);
                              }
                              break;
                              } else if (2 == cell_val) {
                                // success
                                rb_ary_push(arr, rb_str_new2(str));
                                if (debug >= 1) {
                                  printf("MADE-IT... base_ten(%d) resulted in str (%s) of len: %d (suppose to be: %d)\n",base_ten,str,curr_len,path_len);
                                  //rb_funcall(self, rb_intern("draw_matrix"), 2, INT2FIX(y), INT2FIX(x));
                                }
                                free(str);
                                return arr;
                              }
                            }
                            free(str);
                          }
                        }

                        //free(str);
                        // if we got here, then we return an empty array
                          return arr;
                        }
                        YOOO
                        builder.c foo
                      end

                    end

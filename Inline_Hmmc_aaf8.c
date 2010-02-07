#include "ruby.h"
#include <stdio.h>
#include <string.h>
#include <sys/types.h>

# line 95 "hmmc.rb"
static VALUE get_binaries(VALUE self, VALUE _min, VALUE _max, VALUE _matrix) {
  int min = FIX2INT(_min);
  int max = FIX2INT(_max);
  VALUE matrix = (_matrix);

	char* str;
	char* p;
	int c, x, y, j;
	int cell_val;
	int how_big;
	int path_len, mutable_base_ten, base_ten, max_base_ten;
	VALUE arr = rb_ary_new();

    for (path_len=min; path_len<=max; path_len++) {
	  max_base_ten = ((1 << path_len) - 1);
	  for (base_ten=0; base_ten<= max_base_ten; base_ten++) {
	    mutable_base_ten = base_ten;
        how_big = ( sizeof(int)*path_len*sizeof(char) );
        str = malloc( how_big );
        p = str;
	while (mutable_base_ten>0) {
		(mutable_base_ten & 0x1) ? (*p++='1') : (*p++='0');
		mutable_base_ten >>= 1;
	}
	p = str;

	if (2 >= base_ten) {
		if (0 == base_ten) {
			*p = '0';
		}
	} else {
    	for (x=0, j=strlen(p)-1; x<j; x++, j--)
      	c = p[x], p[x] = p[j], p[j] = c;
	}
	    x = 0, y = 0;
	    for (;;) {
		  '0' == *p ? y++ : x++;
		  p++;

		  cell_val = RARRAY_PTR(RARRAY_PTR(matrix)[y])[x];
		  printf("cell_val at x(%d),y(%d): %d\n",x,y,cell_val);
		  if (0 == cell_val) {
		  	break;
		  } else if (2 == cell_val) {
	         rb_ary_push(arr, rb_str_new2(p));
	    	 free(str);
		  	 return (arr);
		  }
	    }
	    free(str);
	  }
	}
	return (arr);
}



#ifdef __cplusplus
extern "C" {
#endif
  void Init_Inline_Hmmc_aaf8() {
    VALUE c = rb_cObject;
    c = rb_const_get(c, rb_intern("Hmmc"));

    rb_define_method(c, "get_binaries", (VALUE(*)(ANYARGS))get_binaries, 3);

  }
#ifdef __cplusplus
}
#endif

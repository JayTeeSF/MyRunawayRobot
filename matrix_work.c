//http://www.linuxhowtos.org/C_C++/socket.htm
//http://pleasemakeanote.blogspot.com/2008/06/2d-arrays-in-c-using-malloc.html

// access w/ matrix[i][j]
int** make_matrix(int width, int height) {
  int **matrix;
  matrix = calloc(width * sizeof(int *));
  for (i = 0; i < width; i++) {
    matrix[i] = calloc(height * sizeof(int));
  }
  return matrix;
}

/**
int** the_matrix = make_matrix(width, height);
for (i=0; i<width; i++) {
  free(matrix[i]);
}
free(matrix);
*/

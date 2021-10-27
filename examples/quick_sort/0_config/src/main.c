#include <stdlib.h>
#include <stdio.h>
#include <strings.h>

#include "compare.h"

#define strEq(strlit, strvar) (0 == strncasecmp((strlit), (strvar), (sizeof(strlit)-1)))

int main (int argc, char** argv) {
  unsigned int seed = 42;  
  unsigned int size = 0;
  enum { lowToHigh, highToLow, random } order;
  int i;

  for (i=1; i<argc; ++i) {
    printf("%d: '%s'\n", i, argv[i]);
    if (0 == strncasecmp("--size=", argv[i], 7)) {
      size = strtoul(argv[i] + 7, NULL, 0);
    } else if (strEq("--lowtohigh", argv[i])) {
      order = lowToHigh;
    } else if (strEq("--hightolow", argv[i])) {
      order = highToLow;
    } else if (strEq("--randomOrderWithSeed=", argv[i])) {
      order = random;
      seed = strtoul(argv[i] + 22, NULL, 0);
    } else {
      exit(-1);
    }
  }
  printf("size:%u,seed:%u,order:%d\n", size, seed, (int)order);
  if (size <= 0) exit(-2);

  int *array = malloc(size * sizeof(int));
  switch(order) {
    case random: {
      srand(seed);
      for (i=0; i<size; ++i) {
        array[i] = rand();
      }
    } break;
    case lowToHigh: {
      for (i=0; i<size; ++i) {
        array[i] = i;
      }
    } break;
    case highToLow: {
      for (i=0; i<size; ++i) {
        array[i] = size-i;
      }
    } break;
  }
  qsort( array, size, sizeof(int), compare );
  return 0;
}

#include "compare.h"

int compare(const void *pa, const void *pb) {
  const int a = (int)pa;
  const int b = (int)pb;
  if (a < b) return -1;
  else if (a > b) return +1;
  else return 0;
}

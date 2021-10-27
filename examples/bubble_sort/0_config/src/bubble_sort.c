// Bubble Sort; Daniel S. Wilkerson
// see License.txt for copyright and terms of use

#include <stdlib.h>             // atoi, getenv
#include <stdio.h>              // scanf, printf
#include <assert.h>             // assert

int capacity = 0;               // size of 'data' array
int size = 0;                   // amount of 'data' that has real data in it
int *data = NULL;               // the data we sort

void bubble_sort(int size, int *data) {
  int *a;
  int *b;
  for(a=data; a<data+size; ++a) {
    // put the smallest element to the right of a into *a
    for(b=a+1; b<data+size; ++b) {
      // move the smaller element to a
      if (*a > *b) {
        // swap without a temporary
        *a ^= *b;
        *b ^= *a;
        *a ^= *b;
      }
    }
  }
}

// ensure we have space for at least new_size elements
void ensure_size(int new_size) {
  if (new_size <= capacity) return;
  int new_capacity = 2*capacity;
  if (new_capacity < 16) new_capacity = 16;
  data = (int *) realloc(data, new_capacity * sizeof *data);
  if (!data) exit(1);           // out of memory
  capacity = new_capacity;
}

int main(int argc, char **argv) {
  // populate the data array
  //
  // Ah, this is an error.  The last time through we are going to
  // make space in the array for the next number, but it is not
  // going to get filled in.  Therefor the sorted array will contain
  // one datum of garbage.  Trend-prof found this bug because the
  // number of iterations of the loop wasn't n*(n-1)/2, but instead
  // [n+1]*([n+1]-1)/2.
  //    for (size=1; 1; ++size) {
  //      ensure_size(size);
  //      int num_scanned = scanf("%d", &(data[size-1])); // data + size - 1
  while(1) {
    int temp;
    int num_scanned = scanf("%d", &temp);
    if (num_scanned == -1) break; // done
    if (num_scanned != 1) exit(1); // scan error
    ++size;
    ensure_size(size);
    data[size-1] = temp;
  }

  // sort it
  bubble_sort(size, data);

  // print it out
  if (getenv("BUBBLE_PRINT")) {
    printf("size=%d\n", size);
    int *start;
    for (start=data; start<data+size; ++start) {
      printf("%d\n", *start);
    }
  }

  return 0;
}

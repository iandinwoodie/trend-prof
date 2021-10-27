CFLAGS :=
CFLAGS += -g -Wall -O0

# Important!  These allow trend-prof to work.
CFLAGS += -fprofile-arcs -ftest-coverage

.SUFFIXES:

.PHONY: all
all: bubble_sort

.PHONY: clean
clean:
	rm -f bubble_sort *.o *.gcda *.gcno

.PHONY: test
test:
	BUBBLE_PRINT=1 ./bubble_sort < in_17_8.dat

bubble_sort: bubble_sort.o
	gcc -o $@ $(CFLAGS) -g -Wall $^

%.o: %.c
	gcc -c -o $@ $(CFLAGS) -g -Wall $<

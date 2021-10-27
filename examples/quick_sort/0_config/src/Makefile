.SUFFIXES:

.PHONY: all clean

all: main

CC := gcc
CFLAGS := -fprofile-arcs -ftest-coverage -g -O3

LD := gcc
LDFLAGS := -fprofile-arcs -ftest-coverage

AR     := ar
RANLIB := ranlib

MAKESO := gcc -shared -fPIC -lc -Wl -fprofile-arcs -ftest-coverage

main: main.o compare.o 
	$(LD) $(LDFLAGS) $^ -o $@ 

main-static: main.o compare.a
	$(LD) $(LDFLAGS) $^ -o $@ 

main-dynamic: main.o compare.so 
	$(LD) $(LDFLAGS) $^ -o $@ 

main.o: main.c compare.h
	$(CC) $(CFLAGS) -c $< -o $@ 

compare.o: compare.c compare.h
	$(CC) $(CFLAGS) -c $< -o $@ 

compare.a: compare.o
	rm -f compare.a
	$(AR) -r compare.a compare.o
	-$(RANLIB) compare.a

compare-dynamic.o: compare.c
	$(CC) $(CFLAGS) -fPIC -c $< -o $@

compare.so: compare-dynamic.o
	$(MAKESO) -Wl,-soname=$@ -o $@ $<


clean:
	rm -f *.o *.gcda *.gcno *.da *.bb *.bbg main main-static main-dynamic compare.a compare.so *~


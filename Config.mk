# This included-makefile is where you set all the options for how you
# would like trend-prof to work for you.

# Comment out this error after you have seen it once.
$(error You must set the BIN variable and possibly other stuff in Config.mk.  Please see the documentation)

# Put the absolute path to the scripts here.
# For example:
BIN := /home/simon/trend-prof
# BIN := /home/dsw/trend-prof-devel

# change these to match your system
PERL := /usr/bin/perl -w -I$(BIN)

TIME := /usr/bin/time -f "(real: %e secs)(user: %U secs)(system: %S secs)"
# TIME := /usr/local/bin/time -f "(real: %e secs)(user: %U secs)(system: %S secs)"

GNUPLOT := gnuplot

# the version of gcov must match the version of gcc that you use to compile your program
# if you just use the gcc in your system path, this should work
GCOV := gcov

# the title of the final results page as in <html><title>$(TITLE)</title>
TITLE := Trend Profile

# some layout options -- see do_4_view
LAYOUT := total evalAt=1e5,top20 evalAt=1e6,top20 evalAt=1e7,top20 evalAt=1e8,top20 exp,top1000 filelist

# include the generic main functionality
CONFIG_MK := this is a non-empty string
include $(BIN)/Driver.mk

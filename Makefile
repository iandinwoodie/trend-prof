#
# see License.txt for copyright and terms of use
#

# Sets up new profdirs via "make profdir/your_path_here".  Runs a
# simple test via "make test".

.SUFFIXES: 

.PHONY: all
all:
	@echo "This project's build process is strange.  Please see the documentation."

.PHONY: profdir/%
profdir/%: 
	@echo "Creating a new profiling directory at $(*)."
	mkdir --parents $*
	mkdir --parents $*/0_config
	ln -s `pwd`/Config.mk $*/Makefile
	@echo "Done.  You must now create some files and directories in $*.  If you haven't done it yet, you must also edit Config.mk.  Please see the documentation."

.PHONY: clean
clean:
	@echo "There is no clean target.  There is nothing to clean."

.PHONY: install
install: 
	@echo "There is no install target yet.  Please see the documentation for install instructions."

.PHONY: config
config: 
	@echo "There is no config target yet.  Please see the documentation for install instructions."

.PHONY: check
check:
	perl -c do_0_srcfind
	perl -c do_1_rawgcov
	perl -c do_2_linewise
	perl -c do_3_fit
	perl -c do_4_view
	perl -c trend_prof_common.pm

.PHONY: test
test: test/bubble_sort test/quick_sort

.PHONY: test-clean
test-clean: test-clean/quick_sort test-clean/bubble_sort

# quick sort example
.PHONY: test/quick_sort
test/quick_sort: examples/quick_sort/0_config/obj examples/quick_sort/Makefile
	@echo
	@echo "******** Running quick_sort example ********"
	cd examples/quick_sort/0_config/src && make clean all && cd -
	cd examples/quick_sort && rm -f 0_config/source_files && make obliterate all && cd -
	@echo
	@echo "SUCCESS!  The example ran without dying.  If you want to sanity check the results do the following."
	@echo "make -C examples/quick_sort run-server/<port>"
	@echo "view http://localhost:<port>/`pwd`/examples/quick_sort/4_view/index.html"
	@echo

.PHONY: test-clean/quick_sort
test-clean/quick_sort:
	$(MAKE) -C examples/quick_sort obliterate
	$(MAKE) -C examples/quick_sort/0_config/src clean
	rm -f examples/quick_sort/0_config/source_files
	rm -f examples/quick_sort/0_config/obj
	rm -f examples/quick_sort/Makefile

examples/quick_sort/0_config/obj: 
	cd examples/quick_sort/0_config && ln -s src obj && cd -

examples/quick_sort/Makefile: 
	cd examples/quick_sort && ln -s ../../Config.mk Makefile && cd -

# bubble sort example
.PHONY: test/bubble_sort
test/bubble_sort: examples/bubble_sort/0_config/obj examples/bubble_sort/Makefile
	@echo
	@echo "******** Running bubble_sort example ********"
	cd examples/bubble_sort/0_config/src && make clean all && cd -
	cd examples/bubble_sort/0_config && make clean workloads && cd -
	cd examples/bubble_sort && rm -f 0_config/source_files && make obliterate all && cd -
	@echo
	@echo "SUCCESS!  The example ran without dying.  If you want to sanity check the results do the following."
	@echo "make -C examples/bubble_sort run-server/<port>"
	@echo "view http://localhost:<port>/`pwd`/examples/bubble_sort/4_view/index.html"
	@echo

.PHONY: test-clean/bubble_sort
test-clean/bubble_sort:
	$(MAKE) -C examples/bubble_sort obliterate
	$(MAKE) -C examples/bubble_sort/0_config clean
	$(MAKE) -C examples/bubble_sort/0_config/src clean
	rm -f examples/bubble_sort/0_config/source_files
	rm -f examples/bubble_sort/0_config/obj
	rm -f examples/bubble_sort/Makefile

examples/bubble_sort/0_config/obj: 
	cd examples/bubble_sort/0_config && ln -s src obj && cd -

examples/bubble_sort/Makefile: 
	cd examples/bubble_sort && ln -s ../../Config.mk Makefile && cd -

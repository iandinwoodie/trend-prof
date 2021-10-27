.SUFFIXES:

# **** workloads

# use the workloads_from_dir to make the workloads file
workloads: input
# note the doubled dollar sign due to make interpolation; it turns
# into one dollar sign
# 	../../workloads_from_dir input '^in0\d+$$' > $@
# I actually want them all though, so I won't use a filter
	../../../workloads_from_dir input > $@
# You could also use a command line of power like the following 
# to create your workloads file.
#	find input -type f -print0 | xargs -0 -l wc -l | perl -ne 'if ($$_ =~ m{^\s*(\d+)\s*input/(.*)$$}) {print "\nworkload:\n   size = $$1\n   name = $$2\n\n";}' >> $@

.PHONY: clean/workloads
clean/workloads:
	rm -f workloads

# **** input

input:
	rm -rf $@
	mkdir $@
	$(MAKE) gen_input/17 gen_input/23 gen_input/47

.PHONY: gen_input
gen_input/%:
	for N in 8 32 64 256 1024 2048 4096; \
          do ./gen_input $$N $* > input/in_$*_$$N.dat; \
        done

.PHONY: clean/input
clean/input:
	rm -rf input

# ****

.PHONY: clean
clean: clean/input clean/workloads

#
# see License.txt for copyright and terms of use
#

# Drives the data gathering and analysis.  Symlinked into new
# profdirs as "Makefile".

all:

# FIX: figure out why this is failing even when it shouldn't
ifndef CONFIG_MK
  $(error Do not run this makefile by itself.  It should only be included by Config.mk)
endif

######################################################################
# You can rename the value of these variables if you want; it should still work :-)
######################################################################

# the user must create these -- see documentation
WORKLOADS      := 0_config/workloads
RUN_WORKLOAD   := 0_config/run_workload
SRC_DIR        := 0_config/src
# OBJ_DIR may be the same as SRC_DIR
OBJ_DIR        := 0_config/obj

# the scripts will create these
SOURCEFILE_MAP := 0_config/source_files
RAWGCOV_DIR    := 1_rawgcov
LINEWISE_DIR   := 2_linewise
FIT_DIR        := 3_fit
VIEW_DIR       := 4_view
CLUSTER_FILE  := 0_config/clusters

######################################################################
# You probably don't want to change anything below here
######################################################################

.SUFFIXES: 

CLUSTER_DEPS :=
CLUSTER_FLAGS :=
ifdef CLUSTER
CLUSTER_FLAGS := --cluster-file=$(CLUSTER_FILE)
CLUSTER_DEPS := $(CLUSTER_FILE)
endif

.PHONY: all
all: $(LINEWISE_DIR) $(FIT_DIR) $(VIEW_DIR)
ifndef EVERYTHING_MODE
all: print-server-message
endif

.PHONY: print-server-message
print-server-message:
	@echo "The main page has been generated, but the file and model pages "
	@echo "will be generated on-demand by the server.  You can run it by typing"
	@echo "  make run-server/1313"
	@echo "Then go to the URL:"
	@echo "  http://localhost:1313/`pwd`/$(VIEW_DIR)/index.html"

.PHONY: run-server/%
run-server/%:
	$(PERL) $(BIN)/run_server --port=$* --data-dir=$(LINEWISE_DIR) --fit-dir=$(FIT_DIR) --view-dir=$(VIEW_DIR) --title="$(TITLE)" $(CLUSTER_FLAGS)

# a couple of targets to remind the user to create some necessary files
.PRECIOUS: $(WORKLOADS)
$(WORKLOADS): 
	@echo "ERROR: You need to create a '$(WORKLOADS)' file.  Please see the documentation."
	@false

.PRECIOUS: $(RUN_WORKLOAD)
$(RUN_WORKLOAD):
	@echo "ERROR: You need to create a '$(RUN_WORKLOAD)' file and make it executable.  Please see the documentation."
	@false

.PRECIOUS: $(SRC_DIR)
$(SRC_DIR): 
	@echo "ERROR: $(SRC_DIR) must be (or be a symlink to) a directory containing the source for your project.  Please see the documentation."
	@false

.PRECIOUS: $(OBJ_DIR)
$(OBJ_DIR):
	@echo "ERROR: $(OBJ_DIR) must be (or be a symlink to) a directory containing the gcov metadata for your project.  $(OBJ_DIR) may be a symlink to $(SRC_DIR).  Please see the documentation."
	@false

# the process

# 0: guess source files
.PRECIOUS: $(SOURCEFILE_MAP)
$(SOURCEFILE_MAP): $(SRC_DIR) $(OBJ_DIR)
	@echo
	@echo -=-=-=-=- Guessing which source files correspond to which gcov metadata -=-=-=-=-
	$(TIME) $(PERL) $(BIN)/do_0_srcfind $(SRC_DIR) $(OBJ_DIR) $@

# 1: run workloads
.PRECIOUS: $(RAWGCOV_DIR)
$(RAWGCOV_DIR): $(WORKLOADS) $(RUN_WORKLOAD) $(SRC_DIR) $(OBJ_DIR) $(SOURCEFILE_MAP)
	@echo
	@echo -=-=-=-=- Running Workloads -=-=-=-=-
	$(TIME) $(PERL) $(BIN)/do_1_rawgcov . $@ $(WORKLOADS) $(RUN_WORKLOAD) $(SOURCEFILE_MAP) $(SRC_DIR) $(OBJ_DIR) $(GCOV)
	@echo

# 2: transpose
.PRECIOUS: $(LINEWISE_DIR)
$(LINEWISE_DIR): $(WORKLOADS) $(RAWGCOV_DIR)
	@echo
	@echo -=-=-=-=- Transposing Raw gcov Data -=-=-=-=-
	$(TIME) $(PERL) $(BIN)/do_2_linewise  $(WORKLOADS) $(RAWGCOV_DIR) $@
	@echo

# 3: fit
.PRECIOUS: $(FIT_DIR)
#$(FIT_DIR): $(LINEWISE_DIR)
$(FIT_DIR):
	@echo
	@echo -=-=-=-=- Constructing Models -=-=-=-=-
	$(TIME) $(PERL) $(BIN)/do_3_fit $(LINEWISE_DIR) $@ 
	@echo

# 4: render html
.PRECIOUS: $(VIEW_DIR)
#$(VIEW_DIR): $(LINEWISE_DIR) $(FIT_DIR) $(CLUSTER_DEPS)
$(VIEW_DIR): $(CLUSTER_DEPS)
	@echo
	@echo -=-=-=-=- Rendering Html Output -=-=-=-=-
ifdef EVERYTHING_MODE
	$(TIME) $(PERL) $(BIN)/do_4_view --data-dir=$(LINEWISE_DIR) --fit-dir=$(FIT_DIR) --view-dir=$@ --title="$(TITLE)" $(addprefix --view=,$(LAYOUT)) $(CLUSTER_FLAGS) --mode=everything_mode
	@echo
	@echo -=-=-=-=- Generating Plots -=-=-=-=-
	$(TIME) find $@ -type f -name "*.gnuplot" -print0 | xargs -0 -l -r $(GNUPLOT) 2>&1
else
	$(TIME) $(PERL) $(BIN)/do_4_view --data-dir=$(LINEWISE_DIR) --fit-dir=$(FIT_DIR) --view-dir=$@ --title="$(TITLE)" $(addprefix --view=,$(LAYOUT)) $(CLUSTER_FLAGS) --mode=index_mode --run-gnuplot
endif
	@echo

.PRECIOUS: $(CLUSTER_FILE)
$(CLUSTER_FILE): $(LINEWISE_DIR)
	@echo
	@echo -=-=-=-=-=- Computing Clusters of Basic Blocks -=-=-=-=-=-
	$(TIME) $(PERL) $(BIN)/clusters.pl $(LINEWISE_DIR) > $@
	@echo

# clarification messages
.PHONY: clean
clean:
	@echo "There is no clean target.  Delete the directories manually if that's what you want."

.PHONY: install
install: 
	@echo "There is no install target.  Please see the documentation."

.PHONY: config
config: 
	@echo "There is no config target.  Please see the documentation."

# really delete all the info and results in this directory
.PHONY: obliterate
obliterate:
	rm -rf $(VIEW_DIR) $(FIT_DIR) $(LINEWISE_DIR) $(RAWGCOV_DIR) $(CLUSTER_FILE) gcov_out source_files
	@if test -e $(SOURCEFILE_MAP); then \
          echo "NOTE: moving the old $(SOURCEFILE_MAP) away."; \
          echo "If you edited it by hand and want to restore it, just move it back."; \
          mv -b $(SOURCEFILE_MAP) $(SOURCEFILE_MAP).old; \
        fi

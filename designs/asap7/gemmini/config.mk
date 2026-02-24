export DESIGN_NICKNAME ?= gemmini
export DESIGN_NAME = gemmini
export PLATFORM    = asap7

-include $(BENCH_DESIGN_HOME)/src/$(DESIGN_NAME)/verilog.mk

export SDC_FILE      = $(BENCH_DESIGN_HOME)/$(PLATFORM)/gemmini/constraint.sdc

export DIE_AREA  = 0 0 200 200
export CORE_AREA = 10 10 190 190

export PLACE_PINS_ARGS = -min_distance 2 -min_distance_in_tracks

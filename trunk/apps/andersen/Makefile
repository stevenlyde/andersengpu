# Add source files here
EXECUTABLE	:= andersen
# Cuda source files (compiled with cudacc)
CUFILES		:= andersen.cu
# C++ source files (compiled with gcc)
CCFILES		:= main.cpp \

CU_DEPS 	:= andersen.h
C_DEPS  	:= andersen.h \

# disable L1 cache
# CUDACCFLAGS	:= -Xptxas -dlcm=cg

# print register usage
# CUDACCFLAGS     := --ptxas-options="-v"

# include debug information
# dbg     = 1

i386=1
verbose		     := 1
fastmath	     := 1
maxregisters	     := 36

################################################################################
# Rules and targets

# user-dependent variables. Please change them for your particular system.
CUDA_INSTALL_PATH ?= $(HOME)/src/cuda-5.0

include ../../common.mk

LIB += -L. -lgzstream  -lz 
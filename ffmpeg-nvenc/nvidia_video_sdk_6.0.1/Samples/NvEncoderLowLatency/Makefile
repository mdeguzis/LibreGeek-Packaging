################################################################################
#
# Copyright 1993-2015 NVIDIA Corporation.  All rights reserved.
#
# NOTICE TO USER:   
#
# This source code is subject to NVIDIA ownership rights under U.S. and 
# international Copyright laws.  
#
# NVIDIA MAKES NO REPRESENTATION ABOUT THE SUITABILITY OF THIS SOURCE 
# CODE FOR ANY PURPOSE.  IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR 
# IMPLIED WARRANTY OF ANY KIND.  NVIDIA DISCLAIMS ALL WARRANTIES WITH 
# REGARD TO THIS SOURCE CODE, INCLUDING ALL IMPLIED WARRANTIES OF 
# MERCHANTABILITY, NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE.   
# IN NO EVENT SHALL NVIDIA BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL, 
# OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS 
# OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE 
# OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE 
# OR PERFORMANCE OF THIS SOURCE CODE.  
#
# U.S. Government End Users.  This source code is a "commercial item" as 
# that term is defined at 48 C.F.R. 2.101 (OCT 1995), consisting  of 
# "commercial computer software" and "commercial computer software 
# documentation" as such terms are used in 48 C.F.R. 12.212 (SEPT 1995) 
# and is provided to the U.S. Government only as a commercial end item.  
# Consistent with 48 C.F.R.12.212 and 48 C.F.R. 227.7202-1 through 
# 227.7202-4 (JUNE 1995), all U.S. Government End Users acquire the 
# source code with only those rights set forth herein.
#
################################################################################
#
# Makefile project only supported on Mac OSX and Linux Platforms)
#
################################################################################

# OS Name (Linux or Darwin)
OSUPPER = $(shell uname -s 2>/dev/null | tr [:lower:] [:upper:])
OSLOWER = $(shell uname -s 2>/dev/null | tr [:upper:] [:lower:])

# Flags to detect 32-bit or 64-bit OS platform
OS_SIZE = $(shell uname -m | sed -e "s/i.86/32/" -e "s/x86_64/64/")
OS_ARCH = $(shell uname -m | sed -e "s/i386/i686/")

# These flags will override any settings
ifeq ($(i386),1)
	OS_SIZE = 32
	OS_ARCH = i686
endif

ifeq ($(x86_64),1)
	OS_SIZE = 64
	OS_ARCH = x86_64
endif

# Flags to detect either a Linux system (linux) or Mac OSX (darwin)
DARWIN = $(strip $(findstring DARWIN, $(OSUPPER)))

# Common binaries
GCC             ?= g++

# Extra user flags
EXTRA_LDFLAGS   ?=
EXTRA_CCFLAGS   ?= -std=c++0x -std=gnu++0x

# OS-specific build flags
ifneq ($(DARWIN),)
      LDFLAGS   := -Xlinker -rpath
      CCFLAGS   := -arch $(OS_ARCH)
else
  ifeq ($(OS_SIZE),32)
      LDFLAGS   += -L/usr/lib64 -lnvidia-encode -ldl
      CCFLAGS   := -m32
  else
      LDFLAGS   += -L/usr/lib64 -lnvidia-encode -ldl
      CCFLAGS   := -m64
  endif
endif

# Debug build flags
ifeq ($(dbg),1)
      CCFLAGS   += -g
      TARGET    := debug
else
      TARGET    := release
endif

# Common includes
INCLUDES      := -I../common/include

# Target rules
all: build

build: NvEncoderLowLatency 

dynlink_cuda.o: ../common/src/dynlink_cuda.cpp
	$(GCC) $(CCFLAGS) $(INCLUDES) -o $@ -c $<
	
NvHWEncoder.o: ../common/src/NvHWEncoder.cpp ../common/inc/NvHWEncoder.h
	$(GCC) $(CCFLAGS) $(EXTRA_CCFLAGS) $(INCLUDES) -o $@ -c $<

NvEncoderCommandParser.o: NvEncoderCommandParser.cpp ../common/inc/nvEncodeAPI.h
	$(GCC) $(CCFLAGS) $(EXTRA_CCFLAGS) $(INCLUDES) -o $@ -c $<

NvEncoderLowLatency.o: NvEncoderLowLatency.cpp ../common/inc/nvEncodeAPI.h NvEncoderLowLatency.h
	$(GCC) $(CCFLAGS) $(EXTRA_CCFLAGS) $(INCLUDES) -o $@ -c $<

NvEncoderPreProcessor.o: NvEncoderPreProcessor.cpp ../common/inc/nvEncodeAPI.h
	$(GCC) $(CCFLAGS) $(EXTRA_CCFLAGS) $(INCLUDES) -o $@ -c $<

NvEncoderLowLatency: NvHWEncoder.o NvEncoderCommandParser.o NvEncoderLowLatency.o NvEncoderPreProcessor.o dynlink_cuda.o
	$(GCC) $(CCFLAGS) -o $@ $+ $(LDFLAGS) $(EXTRA_LDFLAGS)

run: build
	./NvEncoderLowLatency

clean:
	rm -rf NvEncoderLowLatency NvHWEncoder.o NvEncoderCommandParser.o NvEncoderPreProcessor.o dynlink_cuda.o \
	NvEncoderLowLatency.o 


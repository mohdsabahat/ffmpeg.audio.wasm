#!/bin/bash

set -euo pipefail
source $(dirname $0)/var.sh

CONF_FLAGS=(
  --prefix=$BUILD_DIR                                 # install library in a build directory for FFmpeg to include
  --host=i686-gnu                                     # use i686 linux
  --enable-shared=no                                  # not to build shared library
  --disable-asm                                       # not to use asm
  --disable-rtcd                                      # not to detect cpu capabilities
  --disable-doc                                       # not to build docs
  --disable-extra-programs                            # not to build demo and tests
  --disable-stack-protector
)
echo "CONF_FLAGS=${CONF_FLAGS[@]}"

# Build libsamplerate (has autogen.sh)
LIB_PATH1=modules/libsamplerate
(cd $LIB_PATH1 && \
  emconfigure ./autogen.sh && \
  CFLAGS=$CFLAGS emconfigure ./configure "${CONF_FLAGS[@]}")
emmake make -C $LIB_PATH1 clean
emmake make -C $LIB_PATH1 install

# Build rubberband using the single-file compilation approach
# This avoids the need for meson and external dependencies
LIB_PATH=modules/rubberband
RUBBERBAND_SRC=$LIB_PATH/single/RubberBandSingle.cpp

echo "Building rubberband from single-file source..."
mkdir -p $BUILD_DIR/lib
mkdir -p $BUILD_DIR/include/rubberband

# Compile the single-file build to a static library
# Use builtin FFT and resampler (no external dependencies)
em++ $OPTIM_FLAGS -DNDEBUG -ffast-math -ftree-vectorize \
  -DUSE_BQRESAMPLER=1 \
  -DNO_TIMING=1 \
  -DNO_THREADING=1 \
  -DNO_THREAD_CHECKS=1 \
  -DUSE_BUILTIN_FFT=1 \
  -I$LIB_PATH \
  -c $RUBBERBAND_SRC \
  -o $BUILD_DIR/lib/rubberband.o

# Create static library
emar rcs $BUILD_DIR/lib/librubberband.a $BUILD_DIR/lib/rubberband.o
rm $BUILD_DIR/lib/rubberband.o

# Copy headers
cp $LIB_PATH/rubberband/RubberBandStretcher.h $BUILD_DIR/include/rubberband/
cp $LIB_PATH/rubberband/rubberband-c.h $BUILD_DIR/include/rubberband/

# Create pkg-config file
cat > $EM_PKG_CONFIG_PATH/rubberband.pc << EOF
prefix=$BUILD_DIR
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: rubberband
Description: Rubber Band audio time-stretching and pitch-shifting library
Version: 4.0.0
Libs: -L\${libdir} -lrubberband
Cflags: -I\${includedir}
EOF

echo "Rubberband build complete."

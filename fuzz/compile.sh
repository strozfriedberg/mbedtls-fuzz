#!/usr/bin/env bash

# Variable AFL_CC is already taken!
readonly AFL_CC_BIN='afl-clang-fast'
# Alternative (but may run into issues with memory limits):
#readonly AFL_CC_BIN='afl-gcc-fast'

cd ..
find . -name CMakeCache.txt -type f -print | xargs /bin/rm -f
cmake -DCMAKE_C_COMPILER="$AFL_CC_BIN" \
      -DBUILD_SHARED_LIBS=OFF \
      -DENABLE_TESTING=OFF \
      -DCMAKE_BUILD_TYPE=Debug \
      .
make clean all


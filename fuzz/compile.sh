#!/usr/bin/env bash

# Variable AFL_CC is already taken!
readonly AFL_CC_BIN='afl-clang-fast'
# Alternative (but may run into issues with memory limits):
#readonly AFL_CC_BIN='afl-gcc-fast'

checks() {
  # Check if AFL_PATH is set and non-empty
  if [[ -z "$AFL_PATH" ]]; then
    echo "Error: AFL_PATH is not set or is empty."
    exit 1
  fi

  # Check if AFL_CC_BIN is set and executable
  if [[ -z "$AFL_CC_BIN" || ! -x "$(command -v "$AFL_CC_BIN")" ]]; then
    echo "Error: AFL_CC_BIN is not set, empty, or not an executable command in the PATH."
    exit 1
  fi

  # Array of required commands
  local commands=('find' 'cmake' 'make')
  for cmd in "${commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      echo "Error: $cmd is not installed or not in the PATH."
      exit 1
    fi
  done
}

main() {
  pushd ..
  find . -name CMakeCache.txt -type f -print | xargs /bin/rm -f
  cmake -DCMAKE_C_COMPILER="$AFL_CC_BIN" \
        -DBUILD_SHARED_LIBS=OFF \
        -DENABLE_TESTING=OFF \
        -DCMAKE_BUILD_TYPE=Debug \
        .
  make clean all
}

checks
main

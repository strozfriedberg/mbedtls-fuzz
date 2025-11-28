# Fuzzing mbed TLS

## About

This project provides code and tools which allow for fuzzing the [mbed TLS library](https://tls.mbed.org/) using the [american fuzzy lop (afl) fuzzer](https://lcamtuf.coredump.cx/afl/).
An integral part of this project is the code for a self-communicating instance (the client and server run in a single process) of mbed TLS.

More information about the project is available on the Gotham Digital Science blog: 

[Fuzzing the mbed TLS Library](https://web.archive.org/web/20230127213352/https://blog.gdssecurity.com/labs/2015/9/21/fuzzing-the-mbed-tls-library.html)

## Installation

Grab the latest version of afl from the [afl homepage](https://lcamtuf.coredump.cx/afl/) and compile it.
At the time of writing, the latest version is [afl 2.52b](https://lcamtuf.coredump.cx/afl/releases/afl-2.52b.tgz).

Set the `AFL_PATH` environment variable with the folder containing the afl binaries: `export AFL_PATH=/usr/local/src/afl-2.52b`
Extend the `PATH` environment variable with `AFL_PATH`: `export PATH=$PATH:$AFL_PATH`
Alternatively, update the constants of the scripts in the `fuzz` folder so they point to the desired afl compiler.

Run the following command which automatically downloads different versions of mbed TLS, patches them, compiles the code, and sets everything up for fuzzing.

~~~
./setup.sh
~~~

## Fuzzing

Change to `fuzz` subdirectory inside the mbed TLS directory that you wish to fuzz.
Run the `fuzz.sh` script.
Running the script without arguments prints the usage screen including a description of the tool.
The script requires the network packet number (at least `1`) that should be fuzzed and the fuzzer number (use `1` to launch the master instance; higher numbers launch slaves).

In the following example, we launch a master instance to fuzz network packet 3 of the self-communicating mbed TLS 2.0.0 binary:

~~~
cd mbedtls-2.0.0/fuzz
./fuzz.sh 3 1
~~~

## Crash Analysis

If you want to analyze crashes using `gdb`, generate a file containing the paths of the crash files (the path must contain the packet number) and update the constants in `./crash-analysis.sh` accordingly.
Finally, run `./crash-analysis.sh` which allows you to debug the crash using `gdb`.

You can use a command such as the following command to create the file containing the paths of the crash files:

~~~
find . -name 'id*' -type f | grep crashes | sort > crash_files.txt
~~~

## Copyright

Fabian Foerg, Gotham Digital Science, 2015-2025


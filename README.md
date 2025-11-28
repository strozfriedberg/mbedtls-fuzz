# Fuzzing mbed TLS

## About

This project provides code and tools which allow for fuzzing the [mbed TLS library](https://tls.mbed.org/) using the [afl++ fuzzer](https://github.com/AFLplusplus/AFLplusplus).
An integral part of this project is the code for a self-communicating instance (the client and server run in a single process) of mbed TLS.

More information about the project is available on the Gotham Digital Science blog: 

[Fuzzing the mbed TLS Library](https://web.archive.org/web/20230127213352/https://blog.gdssecurity.com/labs/2015/9/21/fuzzing-the-mbed-tls-library.html)

## Installation

Grab the latest version of afl++ from the [afl++ homepage](https://github.com/AFLplusplus/AFLplusplus).
[Build it](https://github.com/AFLplusplus/AFLplusplus/blob/stable/docs/INSTALL.md) instead of running it in Docker to maximize performance.
At the time of writing, the latest version is [afl++ v4.34c](https://github.com/AFLplusplus/AFLplusplus/releases/tag/v4.34c).

Set the `AFL_PATH` environment variable with the folder containing the afl binaries: `export AFL_PATH=/usr/local/src/AFLplusplus`
Extend the `PATH` environment variable with `AFL_PATH`: `export PATH=$PATH:$AFL_PATH`
Alternatively, update the constants of the scripts in the `fuzz` folder so they point to the desired afl compiler.

Run the following command which automatically downloads different versions of mbed TLS, patches them, compiles the code, and sets everything up for fuzzing.

```shell
./setup.sh
```

## Fuzzing

Change to `fuzz` subdirectory inside the mbed TLS directory that you wish to fuzz.
Run the `./fuzz.sh` script.

Running the script without arguments creates the original client and server network packets to be fuzzed and prints the usage screen with a description of the tool.

To fuzz a specific network packet, execute the script with the packet number (minimum of `1`) followed by the fuzzer instance number as command-line arguments:
* Use 1 to initiate the primary fuzzer instance.
* Unique numbers greater than `1` will start additional fuzzer instances.

In the following example, we launch a main fuzzer instance to fuzz network packet 3 of the self-communicating mbed TLS 2.3.0 binary:

```shell
cd mbedtls-mbedtls-2.3.0/fuzz/
./fuzz.sh 3 1
```

The `fuzz.sh` script mounts a tmpfs at `/tmp/afl-ramdisk/mbedtls` containing the fuzzing input and output files for performance reasons.

## Crash Analysis

If you want to analyze crashes using `gdb`, generate a file containing the paths of the crash files (the path must contain the packet number) and update the constants in `./crash-analysis.sh` accordingly.
Finally, run `./crash-analysis.sh` which allows you to debug the crash using `gdb`.

You can use a command such as the following command to create the file containing the paths of the crash files:

```shell
find . -name 'id*' -type f | grep crashes | sort > crash_files.txt
```

## Copyright

Fabian Foerg, Gotham Digital Science, 2015-2025


#!/usr/bin/env bash

readonly SELFTLS_BIN='../selftls'
# Add afl-fuzz to your PATH or the change the following variable:
readonly AFL_FUZZ='afl-fuzz'
readonly RAMDISK_PATH='/tmp/afl-ramdisk/mbedtls'

usage() {
	local progname=$1

	cat <<- EOF
	Usage: $progname [packet number] [fuzzer number]
	
	This program fuzzes mbed TLS using afl-fuzz.
	Calling this program without arguments writes the network packets to files.
	Alternatively, run './selftls' manually to write the packets to files.
	Running './selftls' allows you to check if there are any errors running the program that we fuzz.
	A specific network packet can be replaced with the content from a file which allows for fuzzing that packet.
	To fuzz a specific packet, provide the following two command-line arguments:
	* 1-based packet number, referencing a 'packet-*' file
	* 1 for the main fuzzer or any unique, higher number for each additional fuzzer
	
	mbedtls-fuzz v3.1
	Fabian Foerg <ffoerg@gdssecurity.com>
	https://blog.gdssecurity.com/labs/2015/9/21/fuzzing-the-mbed-tls-library.html
	Copyright 2015-2025 Gotham Digital Science
	EOF
}

main() {
	if [ -z "$2" ]; then
		usage "$0"
		./selftls > /dev/null
		exit 1
	fi

	# Mount RAM disk if necessary
	local is_mounted=$(mount | grep "$RAMDISK_PATH")
	if [ -z "$is_mounted" ]; then
		mkdir -p "$RAMDISK_PATH"
		chmod 777 "$RAMDISK_PATH"
		sudo mount -t tmpfs -o size=512M tmpfs "$RAMDISK_PATH"
	fi
	cp -R . "$RAMDISK_PATH"
	pushd "$RAMDISK_PATH"

	local subfolder=''
	if [ "1" = "$2" ]; then
		# Master creates subfolder
		subfolder="$(date --rfc-3339=seconds)"
		mkdir "$subfolder"
	else
		# Slaves use the folder with newest date in the name
		subfolder="$(find . -maxdepth 1 -type d -regextype posix-egrep -iregex '.*[0-9]{4}-[0-9]{2}-[0-9]{2} .*' -print | sort | tail -1)"
	fi
	pushd "$subfolder"

	local packet_no="$1"
	local FUZZER_NAME="packet-${packet_no}--fuzzer-$2"
	if [ "1" = "$2" ]; then
		# Master mode

		# Create directories
		mkdir -p fin sync

		# Run selftls to get files containing network packets
		rm -f fin/*
		"$SELFTLS_BIN"
		cp "packet-$packet_no" fin

		"$AFL_FUZZ" -i fin -o sync -M "$FUZZER_NAME" "$SELFTLS_BIN" "$packet_no" @@
	else
		# Slave mode
		"$AFL_FUZZ" -i fin -o sync -S "$FUZZER_NAME" "$SELFTLS_BIN" "$packet_no" @@
	fi
}

main "$@"


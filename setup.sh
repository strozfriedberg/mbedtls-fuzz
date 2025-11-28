#!/usr/bin/env bash

readonly ARCHIVE_SUFFIX='.tar.gz'
readonly MBEDTLS_2_28='mbedtls-2.28.10'
readonly SHA_256_2_28='c785ddf2ad66976ab429c36dffd4a021491e40f04fe493cfc39d6ed9153bc246'
readonly MBEDTLS_A=("$MBEDTLS_2_28")
readonly SHA_256_A=("$SHA_256_2_28")
readonly FOLDER_PREFIX='mbedtls-'
readonly NO_TIME=1

checks() {
    # Array of required commands
    commands=('wget' 'shasum' 'tar' 'cmake')
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is not installed or not in the PATH."
            exit 1
        fi
    done
}

main() {
    echo -e "  ************\n  Please make sure to update the constants of scripts in the 'fuzz' folder!\n  ************\n"

    for i in "${!MBEDTLS_A[@]}"; do
        # download if necessary
        wget -nc https://github.com/Mbed-TLS/mbedtls/archive/refs/tags/"${MBEDTLS_A[$i]}${ARCHIVE_SUFFIX}"

        # validate the checksum of the code archives
        CHECKSUM=$(shasum -a 256 "${MBEDTLS_A[$i]}${ARCHIVE_SUFFIX}")

        if [[ "$CHECKSUM" != "${SHA_256_A[$i]}  ${MBEDTLS_A[$i]}${ARCHIVE_SUFFIX}" ]]; then
            echo "Error: ${MBEDTLS_A[$i]}${ARCHIVE_SUFFIX} checksum check failed!"
            exit 1
        fi

        # extract archives
        tar xzf "${MBEDTLS_A[$i]}${ARCHIVE_SUFFIX}"

        VERSION='2'
        INCLUDE_DIR='mbedtls'

        # copy fuzzing code and configuration
        cp -R fuzz "${FOLDER_PREFIX}${MBEDTLS_A[$i]}"
        cp "selftls-${VERSION}.c" "${FOLDER_PREFIX}${MBEDTLS_A[$i]}/fuzz/selftls.c"

        # patch CMakeLists
        pushd "${FOLDER_PREFIX}${MBEDTLS_A[$i]}" && patch -p1 < "../CMakeLists-${VERSION}.patch"; popd

        # make sure TLS time field is constant
        if [[ "$NO_TIME" = "1" ]]; then
            cp "config-${VERSION}.h" "${FOLDER_PREFIX}${MBEDTLS_A[$i]}/include/${INCLUDE_DIR}/config.h"
        else
            pushd "${FOLDER_PREFIX}${MBEDTLS_A[$i]}" && patch -p1 < "../time-${VERSION}.patch"; popd
        fi

        # compile the code
        pushd "${FOLDER_PREFIX}${MBEDTLS_A[$i]}/fuzz" && ./compile.sh; popd
    done

    echo -e "\n  ************\n  If everything compiled correctly, go into one of the 'mbedtls-mbedtls-?.?.?/fuzz/' folders and run './fuzz.sh'\n  ************"
}

checks
main "$@"


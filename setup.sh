#!/usr/bin/env bash

readonly ARCHIVE_SUFFIX='.tar.gz'
readonly MBEDTLS_2_28='mbedtls-2.28.10'
readonly SHA_256_2_28='c785ddf2ad66976ab429c36dffd4a021491e40f04fe493cfc39d6ed9153bc246'
readonly MBEDTLS_2_3='mbedtls-2.3.0'
readonly SHA_256_2_3='1614ee70be99a18ca8298148308fb725aad4ad31c569438bb51655a4999b14f9'
readonly MBEDTLS_2_3='mbedtls-2.3.0'
readonly SHA_256_2_3='1614ee70be99a18ca8298148308fb725aad4ad31c569438bb51655a4999b14f9'
readonly MBEDTLS_2_1='mbedtls-2.1.5'
readonly SHA_256_2_1='01e1325896cbeea55ac50b94e3818218a5bfff065e5b6e7a2a12987f5e187026'
readonly MBEDTLS_1_3='mbedtls-1.3.17'
readonly SHA_256_1_3='5a80deaa77f098733861b53cbabd392cee425b54109c90a6a2142a9662691aa7'
readonly MBEDTLS_A=( "$MBEDTLS_2_28" "$MBEDTLS_2_3" "$MBEDTLS_2_1" "$MBEDTLS_1_3" )
readonly SHA_256_A=( "$SHA_256_2_28" "$SHA_256_2_3" "$SHA_256_2_1" "$SHA_256_1_3" )
readonly FOLDER_PREFIX='mbedtls-'
readonly NO_TIME=1

main() {
    # sudo apt-get install build-essential automake cmake wget

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

        if [[ "${MBEDTLS_A[$i]}" = "$MBEDTLS_1_3" ]]; then
            VERSION='1.3'
            INCLUDE_DIR='polarssl'
        fi

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

main "$@"


#!/bin/sh
# Copyright 2020, Collabora, Ltd.
# SPDX-License-Identifier: BSL-1.0

wrap_line_in_ndef_avr() {
    sed -i -e "/$1/i #ifndef __AVR__" -e "/$1/a #endif" $2
}
copy_wrapped_file() {
    basefn=$1
    fn=$2
    if [ -f "$fn" ]; then
        echo "${basefn}"
        (
            if [ -f "prefixes/${basefn}" ]; then
                cat "prefixes/${basefn}"
            fi
            cat $fn
            if [ -f "suffixes/${basefn}" ]; then
                cat "suffixes/${basefn}"
            fi
        ) > "$DIR/${basefn}"
    fi
}

(
    cd $(dirname $0)
    export DIR=ArduinoAVRCxx
    LIBCXX_DIR=$(cd ../llvm-project/libcxx && pwd)
    rm -rf ${DIR}
    mkdir -p ${DIR}
    mkdir -p ${DIR}/experimental

    # Copy headers
    for fn in "${LIBCXX_DIR}"/include/*; do
        # exclude __config_site.in and CMakeLists.txt
        if echo "$fn" | egrep -v -q "(\.in|\.txt)"; then
            basefn=$(basename "$fn")
            copy_wrapped_file $basefn $fn
        fi
    done
    for fn in "${LIBCXX_DIR}"/include/experimental/*; do
        basefn=experimental/$(basename "$fn")
        copy_wrapped_file $basefn $fn
    done
    
    # Copy source files
    # for fn in "${LIBCXX_DIR}"/include/*; do
    #     if [ -f "$fn" ]; then
    #         # exclude things we can't use
    #         if echo "$fn" | egrep -v -q "(threads|\.txt)"; then
    #             basename "$fn"
    #             cp "$fn" $DIR
    #         fi
    #     fi
    # done
    cp additions/* $DIR
    
    # Wrap multibyte string stuff in conditionals
    sed -i \
    -e '/^using ::mblen.*/i #ifndef _LIBCPP_HAS_NO_MULTIBYTE' \
    -e '/^using ::wcstombs.*/a #endif' \
    ${DIR}/cstdlib

    # Try hacking an implementation into bitset
    sed -i \
    -e '/__storage_type(1) << (_Size/a #elif __SIZEOF_SIZE_T__ == 2' \
    ${DIR}/bitset
    sed -i \
    -e '/__SIZEOF_SIZE_T__ == 2/a : __first_{static_cast<__storage_type>(__v), _Size >= 2 * __bits_per_word ? static_cast<__storage_type>(__v >> __bits_per_word) : static_cast<__storage_type>((__v >> __bits_per_word) & (__storage_type(1) << (_Size - __bits_per_word)) - 1)}' \
    ${DIR}/bitset
    sed -i \
    -e '/__SIZEOF_SIZE_T__ == 2/a #warning "This has not been tested!"' \
    ${DIR}/bitset
    
    # Drop scalbln, scalbn, tgamma entirely
    sed -i \
    -e '/^\/\/ scalbln/i #ifndef __AVR__' \
    -e '/^\/\/ trunc/i #endif' \
    "${DIR}/math.h"
    # Drop nearbyint, nextafter, nexttoward, remainder, remquo, rint entirely
    sed -i \
    -e '/^\/\/ nearbyint/i #ifndef __AVR__' \
    -e '/^\/\/ round/i #endif' \
    "${DIR}/math.h"
    # Drop ilogb, lgamma, llrint, llround, log1p, log2, logb entirely
    sed -i \
    -e '/^\/\/ ilogb/i #ifndef __AVR__' \
    -e '/^\/\/ lrint/i #endif' \
    "${DIR}/math.h"
    # Drop erf, erfc, exp2, expm1 entirely
    sed -i \
    -e '/^\/\/ erf\b/i #ifndef __AVR__' \
    -e '/^\/\/ fdim/i #endif' \
    "${DIR}/math.h"
    # Drop tanh, acosh, asinhatanh entirely
    sed -i \
    -e '/^\/\/ tanh\b/i #ifndef __AVR__' \
    -e '/^\/\/ cbrt/i #endif' \
    "${DIR}/math.h"

    # Drop some missing functions
    wrap_line_in_ndef_avr "using ::vsscanf" ${DIR}/cstdio
    
    # Cope with Arduino's <new> and <new.h>
    mv ${DIR}/new ${DIR}/_libcpp_new.h
    find ${DIR} -type f | xargs sed -i 's/include <new>/include "_libcpp_new.h"/'
    
    # Drop threading-related files
    rm -f \
    ${DIR}/atomic \
    ${DIR}/barrier \
    ${DIR}/future \
    ${DIR}/latch \
    ${DIR}/mutex \
    ${DIR}/semaphore \
    ${DIR}/shared_mutex \
    ${DIR}/thread \
    
    # Drop other unsupported things
    rm -f \
    ${DIR}/filesystem \
    ${DIR}/module.modulemap \
    
)

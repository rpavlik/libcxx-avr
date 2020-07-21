#!/bin/sh
# Copyright 2020, Collabora, Ltd.
# SPDX-License-Identifier: BSL-1.0

wrap_line_in_ndef_avr() {
    sed -i -e "/$1/i #ifndef __AVR__" -e "/$1/a #endif" $2
}

(
    cd $(dirname $0)
    DIR=ArduinoAVRCxx
    LIBCXX_DIR=$(cd ../llvm-project/libcxx && pwd)
    rm -rf ${DIR}
    mkdir -p ${DIR}
    # Copy headers
    
    for fn in "${LIBCXX_DIR}"/include/*; do
        if [ -f "$fn" ]; then
            # exclude __config* and CMakeLists.txt
            if echo "$fn" | egrep -v -q "(\.in|\.txt)"; then
                basefn=$(basename "$fn")
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
                # cp "$fn" $DIR
            fi
        fi
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
    
    # Cope with Arduino's <new> and <new.h>
    mv ${DIR}/new ${DIR}/_libcpp_new.h
    sed -i 's/include <new>/include "_libcpp_new.h"/' ${DIR}/*
    
    # Drop threading-related files
    rm -f \
    ${DIR}/atomic \
    ${DIR}/barrier \
    ${DIR}/future \
    ${DIR}/latch \
    ${DIR}/mutex \
    ${DIR}/semaphore \
    ${DIR}/shared_mutex \
    ${DIR}/threads \

    # Drop other unsupported things
    rm -f \
    ${DIR}/filesystem \
    ${DIR}/module.modulemap \
    
)

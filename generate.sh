#!/bin/sh

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
    # Drop rint entirely
    sed -i \
    -e '/^\/\/ rint/i #ifndef __AVR__' \
    -e '/^\/\/ round/i #endif' "${DIR}/math.h"
    # wrap_line_in_ndef_avr "_LIBCPP_INLINE_VISIBILITY float       tgamma" ${DIR}/math.h
    # wrap_line_in_ndef_avr "_LIBCPP_INLINE_VISIBILITY long double tgamma" ${DIR}/math.h
)

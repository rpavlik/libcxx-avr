//===----------------------------------------------------------------------===//
//
// Copyright 2020, Collabora, Ltd.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//


#include "__config"

#ifdef _LIBCPP_HAS_NO_MULTIBYTE

#ifndef _WCHAR_H_PREFIX
#define _WCHAR_H_PREFIX

#include <stdint.h>

struct mbstate_t {};
static_assert(sizeof(wchar_t) == sizeof(uint16_t));
typedef uint16_t wint_t;
typedef uint16_t wint_type;
#define WEOF EOF

// We don't have these functions, but it's eaiser to pretend we do than excise their usages from libc++
// Trying to use them will produce a link error.
extern size_t wcslen(...);
extern const wchar_t* wmemchr(...);
extern int wmemcmp(...);
extern wchar_t* wmemset(...);
extern wchar_t* wmemcpy(...);
extern wchar_t* wmemmove(...);
#endif // !_WCHAR_H_PREFIX

#else

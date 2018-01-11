/*
 * lxc: linux Container library
 *
 * (C) Copyright IBM Corp. 2007, 2008
 *
 * Authors:
 * Daniel Lezcano <daniel.lezcano at free.fr>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include "config.h"
#include <stdbool.h>

#ifndef __LXC_CAPS_H
#define __LXC_CAPS_H

#if HAVE_SYS_CAPABILITY_H
#include <sys/capability.h>

#if defined(ANDROID) || defined(__ANDROID__)

#define __CAP_BITS   35

/*
 * Do we match the local kernel?
 */
#if !defined(_LINUX_CAPABILITY_VERSION)

# error Kernel <linux/capability.h> does not support library
# error file "cap.h" --> fix and recompile libcap

#elif !defined(_LINUX_CAPABILITY_VERSION_2)

# warning Kernel <linux/capability.h> does not support 64-bit capabilities
# warning and lxc is being built with no support for 64-bit capabilities

# ifndef _LINUX_CAPABILITY_VERSION_1
#  define _LINUX_CAPABILITY_VERSION_1 0x19980330
# endif

# _LIBCAP_CAPABILITY_VERSION  _LINUX_CAPABILITY_VERSION_1
# _LIBCAP_CAPABILITY_U32S     _LINUX_CAPABILITY_U32S_1

#elif defined(_LINUX_CAPABILITY_VERSION_3)

# if (_LINUX_CAPABILITY_VERSION_3 != 0x20080522)
#  error Kernel <linux/capability.h> v3 does not match library
#  error file "cap.h" --> fix and recompile libcap
# else
#  define _LIBCAP_CAPABILITY_VERSION  _LINUX_CAPABILITY_VERSION_3
#  define _LIBCAP_CAPABILITY_U32S     _LINUX_CAPABILITY_U32S_3
# endif

#elif (_LINUX_CAPABILITY_VERSION_2 != 0x20071026)

# error Kernel <linux/capability.h> does not match library
# error file "cap.h" --> fix and recompile libcap

#else

# define _LIBCAP_CAPABILITY_VERSION  _LINUX_CAPABILITY_VERSION_2
# define _LIBCAP_CAPABILITY_U32S     _LINUX_CAPABILITY_U32S_2

#endif

#define NUMBER_OF_CAP_SETS      3   /* effective, inheritable, permitted */
#define CAP_T_MAGIC 0xCA90D0
struct _cap_struct {
    struct __user_cap_header_struct head;
    union {
        struct __user_cap_data_struct set;
	__u32 flat[NUMBER_OF_CAP_SETS];
    } u[_LIBCAP_CAPABILITY_U32S];
};

/* string magic for cap_free */
#define CAP_S_MAGIC 0xCA95D0

/*
 * kernel API cap set abstraction 
 */
    
#define raise_cap(x,set)   u[(x)>>5].flat[set]       |=  (1<<((x)&31))
#define lower_cap(x,set)   u[(x)>>5].flat[set]       &= ~(1<<((x)&31))
#define isset_cap(y,x,set) ((y)->u[(x)>>5].flat[set] &   (1<<((x)&31)))

/*
 * Private definitions for internal use by the library.
 */ 
#define __libcap_check_magic(c,magic) ((c) && *(-1+(__u32 *)(c)) == (magic))
#define good_cap_t(c)        __libcap_check_magic(c, CAP_T_MAGIC)
#define good_cap_string(c)   __libcap_check_magic(c, CAP_S_MAGIC)


/*
 * Opaque capability handle (defined internally by libcap)
 * internal capability representation
 */
typedef struct _cap_struct *cap_t;

/*
 * This is the type used to identify capabilities
 */
typedef int cap_value_t;

/*
 * Set identifiers
 */
typedef enum {
    CAP_EFFECTIVE=0,                        /* Specifies the effective flag */
    CAP_PERMITTED=1,                        /* Specifies the permitted flag */
    CAP_INHERITABLE=2                       /* Specifies the inheritable flag */
} cap_flag_t;

/*
 * These are the states available to each capability
 */
typedef enum {
    CAP_CLEAR=0,                            /* The flag is cleared/disabled */
    CAP_SET=1                               /* The flag is set/enabled */
} cap_flag_value_t;

/*  
 * library debugging
 */
#ifdef DEBUG

#include <stdio.h>
# define _cap_debug(f, x...)  do { \
    fprintf(stderr, "%s(%s:%d): ", __FUNCTION__, __FILE__, __LINE__); \
    fprintf(stderr, f, ## x); \
    fprintf(stderr, "\n"); \
} while (0)
    
# define _cap_debugcap(s, c, set) do { \
    unsigned _cap_index; \
    fprintf(stderr, "%s(%s:%d): %s", __FUNCTION__, __FILE__, __LINE__, s); \
    for (_cap_index=_LIBCAP_CAPABILITY_U32S; _cap_index-- > 0; ) { \
       fprintf(stderr, "%08x", (c).u[_cap_index].flat[set]); \
    } \
    fprintf(stderr, "\n"); \
} while (0)

#else /* !DEBUG */

# define _cap_debug(f, x...)
# define _cap_debugcap(s, c, set)

#endif /* DEBUG */

#endif    /* __ANDROID */

extern int lxc_caps_down(void);
extern int lxc_caps_up(void);
extern int lxc_caps_init(void);

extern int lxc_caps_last_cap(void);

extern bool lxc_cap_is_set(cap_value_t cap, cap_flag_t flag);
#else
static inline int lxc_caps_down(void) {
	return 0;
}
static inline int lxc_caps_up(void) {
	return 0;
}
static inline int lxc_caps_init(void) {
	return 0;
}

static inline int lxc_caps_last_cap(void) {
	return 0;
}

typedef int cap_value_t;
typedef int cap_flag_t;
static inline bool lxc_cap_is_set(cap_value_t cap, cap_flag_t flag) {
	return true;
}
#endif

#define lxc_priv(__lxc_function)			\
	({						\
		__label__ out;				\
		int __ret, __ret2, ___errno = 0;		\
		__ret = lxc_caps_up();			\
		if (__ret)				\
			goto out;			\
		__ret = __lxc_function;			\
		if (__ret)				\
			___errno = errno;		\
		__ret2 = lxc_caps_down();		\
	out:	__ret ? errno = ___errno,__ret : __ret2;	\
	})

#define lxc_unpriv(__lxc_function)			\
	({						\
		__label__ out;				\
		int __ret, __ret2, ___errno = 0;		\
		__ret = lxc_caps_down();		\
		if (__ret)				\
			goto out;			\
		__ret = __lxc_function;			\
		if (__ret)				\
			___errno = errno;		\
		__ret2 = lxc_caps_up();			\
	out:	__ret ? errno = ___errno,__ret : __ret2;	\
	})
#endif

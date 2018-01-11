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

#define _GNU_SOURCE
#include "config.h"

#include <errno.h>
#include <limits.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/prctl.h>

#include "caps.h"
#include "log.h"

lxc_log_define(lxc_caps, lxc);

#if HAVE_SYS_CAPABILITY_H

#ifndef PR_CAPBSET_READ
#define PR_CAPBSET_READ 23
#endif

#if defined(ANDROID) || defined(__ANDROID__)

static int cap_free(void *data_p)
{
    if ( !data_p )
        return 0;

    if ( good_cap_t(data_p) ) {
        data_p = -1 + (__u32 *) data_p;
        memset(data_p, 0, sizeof(__u32) + sizeof(struct _cap_struct));
        free(data_p);
        data_p = NULL;
        return 0;
    }

    if ( good_cap_string(data_p) ) {
        size_t length = strlen(data_p) + sizeof(__u32);
        data_p = -1 + (__u32 *) data_p;
        memset(data_p, 0, length);
        free(data_p);
        data_p = NULL;
        return 0;
    }

    _cap_debug("don't recognize what we're supposed to liberate");
    errno = EINVAL;
    return -1;
}

static cap_t cap_init(void)
{
    __u32 *raw_data;
    cap_t result;

    raw_data = malloc( sizeof(__u32) + sizeof(*result) );

    if (raw_data == NULL) {
        _cap_debug("out of memory");
        errno = ENOMEM;
        return NULL;
    }   

    *raw_data = CAP_T_MAGIC;
    result = (cap_t) (raw_data + 1); 
    memset(result, 0, sizeof(*result));

    result->head.version = _LIBCAP_CAPABILITY_VERSION;
    capget(&result->head, NULL);      /* load the kernel-capability version */

    switch (result->head.version) {
#ifdef _LINUX_CAPABILITY_VERSION_1
    case _LINUX_CAPABILITY_VERSION_1:
        break;
#endif
#ifdef _LINUX_CAPABILITY_VERSION_2
    case _LINUX_CAPABILITY_VERSION_2:
        break;
#endif
#ifdef _LINUX_CAPABILITY_VERSION_3
    case _LINUX_CAPABILITY_VERSION_3:
        break;
#endif
    default:                          /* No idea what to do */
        cap_free(result);
        result = NULL;
        break;
    }   

    return result;
}

static cap_t cap_get_proc(void)
{
    cap_t result;

    /* allocate a new capability set */
    result = cap_init();
    if (result) {
        _cap_debug("getting current process' capabilities");

        /* fill the capability sets via a system call */
        if (capget(&result->head, &result->u[0].set)) {
            cap_free(result);
            result = NULL;
        }   
    }   

    return result;
}

static int cap_set_proc(cap_t cap_d)
{
    int retval;

    if (!good_cap_t(cap_d)) {
        errno = EINVAL;
        return -1; 
    }   

    _cap_debug("setting process capabilities");
    retval = capset(&cap_d->head, &cap_d->u[0].set);

    return retval;
}

/*
 * Return the state of a specified capability flag.  The state is
 * returned as the contents of *raised.  The capability is from one of
 * the sets stored in cap_d as specified by set and value
 */
int cap_get_flag(cap_t cap_d, cap_value_t value, cap_flag_t set,
                 cap_flag_value_t *raised)
{
    /*
     * Do we have a set and a place to store its value?
     * Is it a known capability?
     */

    if (raised && good_cap_t(cap_d) && value >= 0 && value < __CAP_BITS
        && set >= 0 && set < NUMBER_OF_CAP_SETS) {
        *raised = isset_cap(cap_d,value,set) ? CAP_SET:CAP_CLEAR;
        return 0;
    } else {
        _cap_debug("invalid arguments");
        errno = EINVAL;
        return -1;
    }
}

/*
 * raise/lower a selection of capabilities
 */
int cap_set_flag(cap_t cap_d, cap_flag_t set,
                 int no_values, const cap_value_t *array_values,
                 cap_flag_value_t raise)
{
    /*
     * Do we have a set and a place to store its value?
     * Is it a known capability?
     */

    if (good_cap_t(cap_d) && no_values > 0 && no_values <= __CAP_BITS
        && (set >= 0) && (set < NUMBER_OF_CAP_SETS)
        && (raise == CAP_SET || raise == CAP_CLEAR) ) {
        int i;
        for (i=0; i<no_values; ++i) {
            if (array_values[i] < 0 || array_values[i] >= __CAP_BITS) {
                _cap_debug("weird capability (%d) - skipped", array_values[i]);
            } else {
                int value = array_values[i];

                if (raise == CAP_SET) {
                    cap_d->raise_cap(value,set);
                } else {
                    cap_d->lower_cap(value,set);
                }
            }
        }
        return 0;

    } else {

        _cap_debug("invalid arguments");
        errno = EINVAL;
        return -1;

    }
}

/*
 *  Reset the all of the capability bits for one of the flag sets
 */
int cap_clear_flag(cap_t cap_d, cap_flag_t flag)
{
    switch (flag) {
    case CAP_EFFECTIVE:
    case CAP_PERMITTED:
    case CAP_INHERITABLE:
        if (good_cap_t(cap_d)) {
            unsigned i;

            for (i=0; i<_LIBCAP_CAPABILITY_U32S; i++) {
                cap_d->u[i].flat[flag] = 0;
            }
            return 0;
        }
        /*
         * fall through
         */

    default:
        _cap_debug("invalid pointer");
        errno = EINVAL;
        return -1; 
    }   
}

#endif    /* __ANDROID__ */

int lxc_caps_down(void)
{
	cap_t caps;
	int ret;

	/* when we are run as root, we don't want to play
	 * with the capabilities */
	if (!getuid())
		return 0;

	caps = cap_get_proc();
	if (!caps) {
		ERROR("failed to cap_get_proc: %m");
		return -1;
	}

	ret = cap_clear_flag(caps, CAP_EFFECTIVE);
	if (ret) {
		ERROR("failed to cap_clear_flag: %m");
		goto out;
	}

	ret = cap_set_proc(caps);
	if (ret) {
		ERROR("failed to cap_set_proc: %m");
		goto out;
	}

out:
	cap_free(caps);
	return 0;
}

int lxc_caps_up(void)
{
	cap_t caps;
	cap_value_t cap;
	int ret;

	/* when we are run as root, we don't want to play
	 * with the capabilities */
	if (!getuid())
		return 0;

	caps = cap_get_proc();
	if (!caps) {
		ERROR("failed to cap_get_proc: %m");
		return -1;
	}

	for (cap = 0; cap <= CAP_LAST_CAP; cap++) {

		cap_flag_value_t flag;

		ret = cap_get_flag(caps, cap, CAP_PERMITTED, &flag);
		if (ret) {
			if (errno == EINVAL) {
				INFO("Last supported cap was %d", cap-1);
				break;
			} else {
				ERROR("failed to cap_get_flag: %m");
				goto out;
			}
		}

		ret = cap_set_flag(caps, CAP_EFFECTIVE, 1, &cap, flag);
		if (ret) {
			ERROR("failed to cap_set_flag: %m");
			goto out;
		}
	}

	ret = cap_set_proc(caps);
	if (ret) {
		ERROR("failed to cap_set_proc: %m");
		goto out;
	}

out:
	cap_free(caps);
	return 0;
}

int lxc_caps_init(void)
{
	uid_t uid = getuid();
	gid_t gid = getgid();
	uid_t euid = geteuid();

	if (!uid) {
		INFO("command is run as 'root'");
		return 0;
	}

	if (uid && !euid) {
		INFO("command is run as setuid root (uid : %d)", uid);

		if (prctl(PR_SET_KEEPCAPS, 1)) {
			ERROR("failed to 'PR_SET_KEEPCAPS': %m");
			return -1;
		}

		if (setresgid(gid, gid, gid)) {
			ERROR("failed to change gid to '%d': %m", gid);
			return -1;
		}

		if (setresuid(uid, uid, uid)) {
			ERROR("failed to change uid to '%d': %m", uid);
			return -1;
		}

		if (lxc_caps_up()) {
			ERROR("failed to restore capabilities: %m");
			return -1;
		}
	}

	if (uid == euid)
		INFO("command is run as user '%d'", uid);

	return 0;
}

static int _real_caps_last_cap(void)
{
	int fd;
	int result = -1;

	/* try to get the maximum capability over the kernel
	* interface introduced in v3.2 */
	fd = open("/proc/sys/kernel/cap_last_cap", O_RDONLY);
	if (fd >= 0) {
		char buf[32];
		char *ptr;
		int n;

		if ((n = read(fd, buf, 31)) >= 0) {
			buf[n] = '\0';
			errno = 0;
			result = strtol(buf, &ptr, 10);
			if (!ptr || (*ptr != '\0' && *ptr != '\n') || errno != 0)
				result = -1;
		}

		close(fd);
	}

	/* try to get it manually by trying to get the status of
	* each capability indiviually from the kernel */
	if (result < 0) {
		int cap = 0;
		while (prctl(PR_CAPBSET_READ, cap) >= 0) cap++;
		result = cap - 1;
	}

	return result;
}

int lxc_caps_last_cap(void)
{
	static int last_cap = -1;
	if (last_cap < 0) last_cap = _real_caps_last_cap();

	return last_cap;
}

bool lxc_cap_is_set(cap_value_t cap, cap_flag_t flag)
{
	int ret;
	cap_t caps;
	cap_flag_value_t flagval;

	caps = cap_get_proc();
	if (!caps) {
		ERROR("Failed to perform cap_get_proc(): %s.", strerror(errno));
		return false;
	}

	ret = cap_get_flag(caps, cap, flag, &flagval);
	if (ret < 0) {
		ERROR("Failed to perform cap_get_flag(): %s.", strerror(errno));
		cap_free(caps);
		return false;
	}

	cap_free(caps);
	return flagval == CAP_SET;
}

#endif

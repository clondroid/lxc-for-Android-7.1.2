LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := libcap
LOCAL_SRC_FILES := cap_alloc.c cap_proc.c cap_extint.c cap_flag.c cap_text.c
LOCAL_C_INCLUDES += external/libcap/libcap/include
LOCAL_CFLAGS := -O2 -W -Wall
LOCAL_COPY_HEADERS_TO := sys
LOCAL_COPY_HEADERS := include/sys/capability.h
include $(BUILD_SHARED_LIBRARY)

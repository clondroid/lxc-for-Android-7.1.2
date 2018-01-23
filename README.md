# Prerequisite

lxc requires some SELinux libs/tools and libcap which is not supported in essential Android, for easier maintenance, we collect the following required packages into this repository.

- lxc android libcap (https://github.com/abstrakraft/lxc-android-libcap)
  - only libcap is required
- SELinux libs and tools
  - for compatibility reasons, we use the SELinux package in essential Android source code base
  - external/selinux
    - libselinux: external/selinux/libselinux
      - NOT external/libselinux which is a small port of libselinuxfor Android framework
    - libsepol: external/selinux/libsepol
    - setfiles: external/selinux/policycoreutils/setfiles 
  - lxc: [lxc-2.0.7](https://github.com/lxc)

Before you can start build these packages, please following the steps below to get prepared for compiling.

- git clone this repsoitory (lxc-for-Android-7.1.2) source into, say "~/cba/lxc" 
  - and "~/cba/lxc" will be $LXC_HOME
- Create the following 2 directories
  - $LXC_HOME/android-libs
    - temporary directory for install include and libs required for building lxc
    - "$LXC_HOME/android-libs" will be $ANDROID_LIBS 
  - /odm
    - This is directory on which lxc tools and libs will be installed
    - You can package this directory on to your Android development device 
- Install the following essential AOSP include and libraries
  - copy from your AOSP source 
    - external/pcre/pcre.h --> ${ANDROID_LIBS}/include/pcre.h
    - out/target/product/marlin/system/lib64/libpcre.so, libc++.so  --> ${ANDROID_LIBS}/lib/
- Android NDK 
  - Android container project uses android-ndk-r15b, other NDK (android-ndk-r15b above) release should also work.
  - Install [Android standalone NDK](https://developer.android.com/ndk/guides/standalone_toolchain.html)
    - sudo ${NDK}/build/tools/make\_standalone\_toolchain.py --arch arm64 --api 24 --stl=libc++ --install-dir=/opt/toolchain/android-toolchain-arm_64-4.9-android-24 --force
    - sudo ${NDK}/build/tools/make\_standalone\_toolchain.py --arch x86\_64 --api 24 --stl=libc++ --install-dir=/opt/toolchain/android-toolchain-x86\_64-4.9-android-24 --force

# Environment setups

you can use the following target platform dependent environment setup script to build these packages.

- please adjust $ANDROID_LIBS, $ANDROID_SDK_HOME, $ANDROID_NDK_HOME, $ANDROID_STANDALONE_TOOLCHAIN_HOME in the script accordingly

**[envsetup_arm_64.sh]**
``` shell
export ANDROID_SDK_HOME=/home/sting/local/android-sdk-linux
export ANDROID_NDK_HOME=/home/sting/local/android-ndk-r15b
export ANDROID_STANDALONE_TOOLCHAIN_HOME=/opt/toolchain/android-toolchain-arm_64-4.9-android-24
export SYSROOT=$ANDROID_STANDALONE_TOOLCHAIN_HOME/sysroot

# User specific environment and startup programs
PATH=${ANDROID_NDK_HOME}
PATH=$PATH:${ANDROID_SDK_HOME}/tools:${ANDROID_SDK_HOME}/platform-tools
PATH=$PATH:${ANDROID_STANDALONE_TOOLCHAIN_HOME}/bin:/usr/local/sbin:/usr/local/bin
PATH=$PATH:/usr/sbin:/usr/bin:/sbin:/bin
export PATH=$PATH

# Tell configure what tools to use.
export BUILD_TARGET_HOST=aarch64-linux-android
export AR=$BUILD_TARGET_HOST-ar
export AS=$BUILD_TARGET_HOST-clang
export CC=$BUILD_TARGET_HOST-clang
export CXX=$BUILD_TARGET_HOST-clang++
export LD=$BUILD_TARGET_HOST-ld
export STRIP=$BUILD_TARGET_HOST-strip
export RANLIB=$BUILD_TARGET_HOST-ranlib

# Tell configure what flags Android requires.
export CFLAGS="-fPIE -fPIC --sysroot=$SYSROOT"
export LDFLAGS="-pie"

# SELinux specifics
BASEDIR=$(pwd)
export ANDROID_LIBS="$BASEDIR/../android-libs/arm_64"
export CFLAGS="$CFLAGS -I$ANDROID_LIBS/include"
export LDFLAGS="$LDFLAGS -L$ANDROID_LIBS/lib"

export ODMDIR=/odm
```

**[envsetup_x86_64.sh]**
``` shell
export ANDROID_SDK_HOME=/home/sting/local/android-sdk-linux
export ANDROID_NDK_HOME=/home/sting/local/android-ndk-r15b
export ANDROID_STANDALONE_TOOLCHAIN_HOME=/opt/toolchain/android-toolchain-x86_64-4.9-android-24
export SYSROOT=$ANDROID_STANDALONE_TOOLCHAIN_HOME/sysroot

# User specific environment and startup programs
PATH=${ANDROID_NDK_HOME}
PATH=$PATH:${ANDROID_SDK_HOME}/tools:${ANDROID_SDK_HOME}/platform-tools
PATH=$PATH:${ANDROID_STANDALONE_TOOLCHAIN_HOME}/bin:/usr/local/sbin:/usr/local/bin
PATH=$PATH:/usr/sbin:/usr/bin:/sbin:/bin
export PATH=$PATH

# Tell configure what tools to use.
export BUILD_TARGET_HOST=x86_64-linux-android
export AR=$BUILD_TARGET_HOST-ar
export AS=$BUILD_TARGET_HOST-clang
export CC=$BUILD_TARGET_HOST-clang
export CXX=$BUILD_TARGET_HOST-clang++
export LD=$BUILD_TARGET_HOST-ld
export STRIP=$BUILD_TARGET_HOST-strip
export RANLIB=$BUILD_TARGET_HOST-ranlib

# Tell configure what flags Android requires.
export CFLAGS="-fPIE -fPIC --sysroot=$SYSROOT"
export LDFLAGS="-pie"

# SELinux specifics
BASEDIR=$(pwd)
export ANDROID_LIBS="$BASEDIR/../android-libs/x86_64"
export CFLAGS="$CFLAGS -I$ANDROID_LIBS/include"
export LDFLAGS="$LDFLAGS -L$ANDROID_LIBS/lib"

export ODMDIR=/odm
```

# Building libcap

Following the steps below to build and install libcap

- libcap include and static library will be install under "$ANDROID_LIBS"
  
``` shell
$ cd $LXC_HOME
$ source ./envsetup_x86_64.sh  or  source ./envsetup_arm_64.sh

$ cd $LXC_HOME/lxc-android-libcap/libcap/
$ ./build.sh
```

# Building SElinux

Following the steps below to build and install SELinux

- SELinux include and static library will be install under "$ANDROID_LIBS"
- SELinux tools and commands will be install in "$ODM/bin"

``` shell
$ cd $LXC_HOME
$ source ./envsetup_x86_64.sh  or  source ./envsetup_arm_64.sh

$ cd $LXC_HOME/selinux-pixel_7.1.2_r17)
$ ./build.sh
```

# Build lxc

Following the steps below to build and install lxc package

- lxc package will be install under "$ODM"

``` shell
$ cd $LXC_HOME
$ source ./envsetup_x86_64.sh  or  source ./envsetup_arm_64.sh

$ cd $LXC_HOME/lxc)
$ ./build.sh
```

# Packaging lxc tools and packages binaries

After successfully building lxc tools and packages, the executalbe binaries will be install onto "/odm", you can directory copy this directory onto your device if necessary. 

```
/odm
├── bin
│   ├── avcstat
│   ├── ...
│   ├── getfilecon
│   ├── ...
│   ├── lxc-start
│   ├── lxc-stop
│   ├── ...
│   ├── setfiles
│   └── ...
├── containers
├── etc
│   ├── ...
│   └── lxc
│       └── default.conf
├── include
│   └── ...
├── lib
│   ├── ...
│   ├── liblxc.so
│   ├── lxc
│   │   └── ...
...
├── libexec
│   └── lxc
│       ├── ...
├── sbin
│   ├── ...
├── share
│   └── lxc
...
```

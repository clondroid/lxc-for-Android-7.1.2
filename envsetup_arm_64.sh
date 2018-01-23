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

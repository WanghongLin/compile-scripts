#!/bin/sh

# librtmp build script for android
# Copyright 2017 Wanghong Lin 
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# 	http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 

export KNRM="\e[0m"
export KRED="\e[31m"
export KGRN="\e[32m"
export KYEL="\e[33m"
export KBLU="\e[34m"
export KMAG="\e[35m"
export KCYN="\e[36m"
export KWHT="\e[37m"

[ $# -ne 1 ] && {
    printf "${KRED}$0 /path/to/openssldir${KNRM}\n"
	exit 0
}

[ ! -d $1 ] && {
    printf "${KRED}Not a valid directory $1${KNRM}\n"
	exit 0
}

printf "${KGRN}Using openssl $1/{armeabi,arm64-v8a}${KNRM}\n"

__output_dir=`pwd`/out/android
rm -rf $__output_dir

make clean
openssldir=$1/armeabi
export PKG_CONFIG_PATH=${openssldir}/lib/pkgconfig:$PKG_CONFIG_PATH
export XCFLAGS="--sysroot $ANDROID_NDK_ROOT/platforms/android-9/arch-arm `pkg-config --cflags openssl`"
export XLDFLAGS="--sysroot $ANDROID_NDK_ROOT/platforms/android-9/arch-arm `pkg-config --libs openssl`"
export CROSS_COMPILE=$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64/bin/arm-linux-androideabi-
make prefix=${__output_dir}/armeabi SHARED=no install

unset PKG_CONFIG_PATH
make clean
openssldir=$1/arm64-v8a
export PKG_CONFIG_PATH=${openssldir}/lib/pkgconfig:$PKG_CONFIG_PATH
export XCFLAGS="--sysroot $ANDROID_NDK_ROOT/platforms/android-21/arch-arm64 `pkg-config --cflags openssl`"
export XLDFLAGS="--sysroot $ANDROID_NDK_ROOT/platforms/android-21/arch-arm64 `pkg-config --libs openssl`"
export CROSS_COMPILE=$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-4.9/prebuilt/darwin-x86_64/bin/aarch64-linux-android-
make prefix=${__output_dir}/arm64-v8a SHARED=no install

printf "${KRED}Build finish, output at ${__output_dir}${KNRM}\n"

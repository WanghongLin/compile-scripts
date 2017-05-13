#!/bin/sh

# A simple script to build openssl for Android
# This script only work in Mac OS X with openssl 1.0.2k
#
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

_archive_name="openssl-1.0.2k"
_archive_suffix=".tar.gz"

function download_archive()
{
	printf "${KRED}Downloading ${_archive_name}${_archive_suffix}${KNRM}\n"
	curl -sL -o ${_archive_name}${_archive_suffix} https://www.openssl.org/source/${_archive_name}${_archive_suffix}
	tar zxvf ${_archive_name}${_archive_suffix}
}

[ ! -d ${_archive_name} ] && download_archive 

cd ${_archive_name}

__install_root=`pwd`/build_out/android
rm -rf $__install_root

function run_build()
{
	# create PIE
	gsed -i 's/^CFLAG.*$/& -fPIE -pie/' Makefile
	make -j8 && make install_sw
}

# build_armv7
export ANDROID_DEV=$ANDROID_NDK_ROOT/platforms/android-9/arch-arm/usr
export CC=$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64/bin/arm-linux-androideabi-gcc
export RANLIB=$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64/bin/arm-linux-androideabi-ranlib
export AR=$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64/bin/arm-linux-androideabi-ar
export NM=$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64/bin/arm-linux-androideabi-nm

make clean

./Configure no-shared \
	--prefix=$__install_root/armeabi \
	--openssldir=$__install_root/armeabi \
	android-armv7
run_build

# build_arm64
export ANDROID_DEV=$ANDROID_NDK_ROOT/platforms/android-21/arch-arm64/usr
export CC=$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-4.9/prebuilt/darwin-x86_64/bin/aarch64-linux-android-gcc
export RANLIB=$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-4.9/prebuilt/darwin-x86_64/bin/aarch64-linux-android-ranlib
export AR=$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-4.9/prebuilt/darwin-x86_64/bin/aarch64-linux-android-ar
export NM=$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-4.9/prebuilt/darwin-x86_64/bin/aarch64-linux-android-nm

make clean 

./Configure no-shared \
	--prefix=$__install_root/arm64-v8a \
	--openssldir=$__install_root/arm64-v8a \
	android
run_build

printf "${KRED}Done output to $__install_root${KNRM}\n"

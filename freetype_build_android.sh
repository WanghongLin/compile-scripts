#!/bin/bash

# Simple script to build freetype for Android used in FFmpeg project
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

make clean_project && make distclean
export CC=arm-linux-androideabi-gcc
export CFLAGS="-fPIC --sysroot=$ANDROID_NDK_ROOT/platforms/android-9/arch-arm"
export LDFLAGS="--sysroot=$ANDROID_NDK_ROOT/platforms/android-9/arch-arm"

./configure --host=arm-linux --with-pic='PIC' --prefix=`pwd`/out/armeabi \
	--with-harfbuzz=no --with-png=no --with-zlib=no \
	--enable-shared=no --enable-static=yes

make -j4 && make install
cp -r `pwd`/out/armeabi `pwd`/out/armeabi-v7a

make clean_project && make distclean
export CC=aarch64-linux-android-gcc
export CFLAGS="-fPIC --sysroot=$ANDROID_NDK_ROOT/platforms/android-21/arch-arm64"
export LDFLAGS="--sysroot=$ANDROID_NDK_ROOT/platforms/android-21/arch-arm64"

./configure --host=aarch64-linux --with-pic='PIC' --prefix=`pwd`/out/arm64-v8a \
	--with-harfbuzz=no --with-png=no --with-zlib=no \
	--enable-shared=no --enable-static=yes

make -j4 && make install

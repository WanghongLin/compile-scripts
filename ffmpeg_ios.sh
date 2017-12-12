#!/bin/bash
#
# A simple script to build ffmpeg for ios on mac os x
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

function build_one()
{
	arch=$1
	if [ "$arch" = "i386" -o "$arch" = "x86_64" ]
	then
		sdk=iphonesimulator
		[ "$arch" = "i386" ] && cpu="x86" || cpu="x86_64"
	else
		sdk=iphoneos
		[ "$arch" = "armv7" ] && cpu="cortex-a8" || cpu="generic"
	fi

	export CC=$(xcrun --sdk $sdk --find clang)
	export CFLAGS="-arch $arch -miphoneos-version-min=8.1"
	export LDFLAGS=$CFLAGS

	sysroot=$(xcrun --sdk $sdk --show-sdk-path)
	prefix=`pwd`/ios/$arch
	rm -rf $prefix

	make distclean

	PATH=$HOME/Stalagmite:$PATH ./configure \
		--enable-cross-compile \
		--arch=$arch \
		--cpu=$cpu \
		--target-os=darwin \
		--cc=$CC \
		--sysroot=$sysroot \
		--enable-pic \
		--disable-doc \
		--disable-programs \
		--disable-debug \
		--disable-encoders \
		--disable-decoders \
		--disable-muxers \
		--disable-demuxers \
		--disable-filters \
		--prefix=$prefix \
		--disable-asm \
		--enable-encoder=mjpeg,jpeg2000,png,aac,h264_videotoolbox,dnxhd \
		--enable-decoder=mjpeg,jpeg2000,png,aac,h264,dnxhd \
		--enable-muxer=image2,mp4,mov,m4v \
		--enable-demuxer=image2,mjpeg,mov,m4v \
		--enable-filter=scale,drawtext,transpose,copy,movie,overlay
		#--cpu=cortex-a8
		#--disable-asm
		make -j8 install && libtool -static -o $prefix/libffmpeg.a `find $prefix -name "*.a"` && \

		# create shared library, more concise than static library
		$CC -shared $CFLAGS -isysroot $sysroot \
		-framework CoreData \
		-framework CoreMedia \
		-framework VideoToolbox \
		-framework AVFoundation \
		-framework CoreVideo \
		-framework CoreFoundation \
		-framework Foundation \
		-Wl,-lz,-liconv -Wl,-all_load `find $prefix/lib -name "*.a"` \
		-miphoneos-version-min=`xcrun --sdk $sdk --show-sdk-version` \
		-o $prefix/libffmpeg.dylib
}

# TODO: bitcode support?
for arch in armv7 arm64 i386 x86_64
do
	build_one $arch
done

__output_root=`pwd`/ios
rm -rf $__output_root/libffmpeg.{a,dylib}
find $__output_root -name "libffmpeg.a" | awk -F/ '{print "-arch", $(NF-1), $0}' |xargs lipo -create -output `pwd`/ios/libffmpeg.a
find $__output_root -name "libffmpeg.dylib" | awk -F/ '{print "-arch", $(NF-1), $0}' |xargs lipo -create -output `pwd`/ios/libffmpeg.dylib

# creaet static framework
mkdir -p $__output_root/ffmpeg.framework/Headers
[ -f $__output_root/libffmpeg.a ] && mv -vf $__output_root/libffmpeg.a $__output_root/ffmpeg.framework/ffmpeg
cp -vrf $__output_root/arm64/include/lib* $__output_root/ffmpeg.framework/Headers/

# create shared framework
mkdir -p $__output_root/FFmpegShared.framework/Headers
[ -f $__output_root/libffmpeg.dylib ] && mv -vf $__output_root/libffmpeg.dylib $__output_root/FFmpegShared.framework/FFmpegShared
cp -vrf $__output_root/arm64/include/lib* $__output_root/FFmpegShared.framework/Headers/

#!/bin/bash
# Copyright (C) 2016 Wanghong Lin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

declare -a ARCH_ABI
declare -a ARCH
declare -a CROSS_PREFIX
declare -a SYSROOT
declare -a E_CFLAGS

ARCH_ABI[0]=armeabi
ARCH_ABI[1]=armeabi-v7a
ARCH_ABI[2]=arm64-v8a

ARCH[0]=arm
ARCH[1]=arm
ARCH[2]=arm64

SYSROOT[0]=$ANDROID_NDK_ROOT/platforms/android-9/arch-arm
SYSROOT[1]=$ANDROID_NDK_ROOT/platforms/android-9/arch-arm
SYSROOT[2]=$ANDROID_NDK_ROOT/platforms/android-21/arch-arm64

CROSS_PREFIX[0]=arm-linux-androideabi-
CROSS_PREFIX[1]=arm-linux-androideabi-
CROSS_PREFIX[2]=aarch64-linux-android-

HOST[0]=arm-linux
HOST[1]=arm-linux
HOST[2]=aarch64-linux

E_CFLAGS[0]="-O3"
E_CFLAGS[1]="-O3 -march=armv7-a -mfpu=neon -mfloat-abi=softfp"
E_CFLAGS[2]="-O3"

export NCPUS=$(sysctl -n hw.ncpu)
VERBOSE=1

if [ $VERBOSE == 1 ];
then
	V=
else
	V="&>/dev/null"
fi

LIB_WEBP_ROOT=../libwebp-ndk

function build_one()
{
	echo "Build for ABI: $1, ARCH: $2, CROSS_PREFIX: $3, HOST: $4"
	echo "SYSROOT: $5, EXTRA_FLAGS: ${@:6}"
	export _abi=$1
	export _arch=$2
	export _cross_prefix=$3
	export _host=$4
	export _sysroot=$5
	export _extra_flags=${@:6}

	if [ $_host == "arm-linux" ];then
		#export _disable_asm="--disable-asm"
		export _disable_asm=
	else
		export _disable_asm=
	fi
	
	(cd ../x264 && make clean &>/dev/null && make distclean &>/dev/null && \
		./configure --cross-prefix=$_cross_prefix \
		--prefix=`pwd`/out \
		--sysroot=$_sysroot --host=$_host \
		--extra-cflags="$_extra_flags -fPIC" --enable-pic $_disable_asm \
		--enable-static &>/dev/null && make -j$NCPUS &>/dev/null)

	rm -rf out/$_abi && make clean &>/dev/null && make distclean &>/dev/null
	find compat -name "*.[od]" -delete

	export PKG_CONFIG_PATH=/Users/wanghong/Downloads/freetype-2.6.3/out/$_abi/lib/pkgconfig:/Users/wanghong/Developments/libwebp-ndk/obj/local/$_abi:../x264/out/lib/pkgconfig

	./configure --enable-cross-compile \
		--host-cc=/Library/Developer/CommandLineTools/usr/bin/cc \
		--pkg-config=/opt/local/bin/pkg-config \
		--arch=$_arch \
		--cross-prefix=$_cross_prefix \
		--target-os=android \
		--enable-runtime-cpudetect \
		--enable-hardcoded-tables \
		--prefix=out/$_abi \
		--sysroot=$_sysroot \
		--disable-encoders \
		--enable-encoder=aac,libx264,mjpeg,png,libwebp,gif \
		--disable-decoders \
		--enable-decoder=aac,mjpeg,png,webp,h264 \
		--disable-filters \
		--enable-filter=scale,scale2ref,copy,movie,resample,aresample,transpose,overlay,drawtext,paletteuse,palettegen,fps,split \
		--disable-demuxers \
		--enable-demuxer=aac,h264,mov,image2,concat \
		--disable-muxers \
		--enable-muxer=h264,mp4,mov,image2,webp,gif \
		--enable-pic \
		--disable-shared \
		--enable-static \
		--disable-symver \
		--enable-gpl \
		--enable-libx264 \
		--enable-libfreetype \
		--enable-libwebp \
		--disable-ffplay \
		--disable-ffprobe \
		--disable-ffserver \
		--disable-network \
		--disable-doc \
		--extra-cflags="-I../x264 -fPIC -fPIE $_extra_flags" \
		--extra-ldflags="-L../x264" \
		--extra-ldlibflags="-shared" \
		--extra-ldexeflags="-fPIE -pie" $V
		#--extra-cflags="-I../x264-snapshot-20151118-2245 -fPIE -fPIC" \
		#--extra-ldflags="-L../x264-snapshot-20151118-2245 -fPIE -pie"
		if [ $_host == "aarch64-linux" ];then
			# the linker will use the library under /opt/local/lib/libfreetype.a
			# that will cause undefined reference error
			# use the file ffbuild/config.mak for new ffmpeg version
			sed -i ".bak" '/EXTRALIBS/{s#-L/opt/local/lib ##;}' ffbuild/config.mak
		fi
		make -j$NCPUS $V && make install $V
		ANDROID_JNI_LIBS=/Users/wanghong/AndroidStudioProjects/GetRemark/ffmpeg/src/main/jniLibs/$_abi
		mkdir -p $ANDROID_JNI_LIBS
		${_cross_prefix}gcc -shared -o out/$_abi/libffmpeg.so -Wl,-soname,libffmpeg.so -Wl,--whole-archive `find ../x264 out/$_abi -name "*.a" | xargs` -Wl,--no-whole-archive \
			--sysroot $_sysroot `pkg-config --libs libwebp freetype2` -lm -lz
		${_cross_prefix}strip --strip-unneeded out/$_abi/libffmpeg.so
		${_cross_prefix}gcc -std=c99 -o out/$_abi/libffmpege.so ffmpeg.c ffmpeg_filter.c ffmpeg_opt.c ffmpeg_hw.c cmdutils.c \
			--sysroot ${_sysroot} \
			-I`pwd` -L`pwd`/out/$_abi -lffmpeg -lm -lz -fPIE -pie
		${_cross_prefix}strip --strip-unneeded out/$_abi/libffmpege.so
		cp -vf out/$_abi/libffmpeg*.so $ANDROID_JNI_LIBS
		#cp -vf out/$_abi/bin/ffmpeg out/$_abi/lib/libffmpeg.so
		#cp -vf out/$_abi/lib/*.so $ANDROID_JNI_LIBS
}

$ANDROID_NDK_ROOT/ndk-build -C $LIB_WEBP_ROOT/jni

for i in `seq 2 2`
do
	a=`eval echo ${ARCH_ABI[$i]}`
	arch=`eval echo ${ARCH[$i]}`
	c=`eval echo ${CROSS_PREFIX[$i]}`
	h=`eval echo ${HOST[$i]}`
	s=`eval echo ${SYSROOT[$i]}`
	e=`eval echo ${E_CFLAGS[$i]}`
	build_one $a $arch $c $h $s $e
done

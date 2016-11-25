#!/bin/bash
#
# Build script for x264 for Android
# 
# Copyright 2016 Wanghong Lin
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

__ScriptVersion="v0.1"

VERBOSE='&>/dev/null'
__ANDROID_NDK_ROOT=
__OUTPUT=

#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
function usage ()
{
	echo "Usage :  $0 [options] [--]

    Options:
    -h|help       Display this message
    -v|version    Display script version
    -n|ndk        Specify Andrid ndk root
    -o|output     Specify output directory
    -d|debug      Verbose mode, 0 or 1"

}    # ----------  end of function usage  ----------

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------

while getopts ":hvn:d" opt
do
  case $opt in

	h|help     )  usage; exit 0   ;;

	v|version  )  echo "$0 -- Version $__ScriptVersion"; exit 0   ;;

	n|ndk      )  __ANDROID_NDK_ROOT=$OPTARG ;;

	d|debug    )  VERBOSE='' ;;

	* )  echo -e "\n  Option does not exist : $OPTARG\n"
		  usage; exit 1   ;;

  esac    # --- end of case ---
  shift $(($OPTIND-1))
done

[ x$__ANDROID_NDK_ROOT != x ] && {
    ANDROID_NDK_ROOT=$__ANDROID_NDK_ROOT
	printf '\e[31mUsing NDK root set from argument\e[30m\n'
}

[ x$__OUTPUT == x ] && __OUTPUT=`pwd`/out

printf "\e[32mNDK root is $ANDROID_NDK_ROOT\e[30m\n"
printf "\e[32mOutput is $__OUTPUT\e[30m\n"

git submodule update --init --remote x264

declare -a ARCH_ABI
declare -a CROSS_PREFIX
declare -a SYSROOT
declare -a E_CFLAGS

ARCH_ABI[0]=armeabi
ARCH_ABI[1]=armeabi-v7a
ARCH_ABI[2]=arm64-v8a

SYSROOT[0]=$ANDROID_NDK_ROOT/platforms/android-9/arch-arm
SYSROOT[1]=$ANDROID_NDK_ROOT/platforms/android-9/arch-arm
SYSROOT[2]=$ANDROID_NDK_ROOT/platforms/android-21/arch-arm64

CROSS_PREFIX[0]=arm-linux-androideabi-
CROSS_PREFIX[1]=arm-linux-androideabi-
CROSS_PREFIX[2]=aarch64-linux-android-

E_CFLAGS[0]="-O3"
E_CFLAGS[1]="-O3 -march=armv7-a -mfpu=neon -mfloat-abi=softfp"
E_CFLAGS[2]="-O3"

cd x264

for i in `seq 0 2`
do
	a=`eval echo ${ARCH_ABI[$i]}`
	s=`eval echo ${SYSROOT[$i]}`
	c=`eval echo ${CROSS_PREFIX[$i]}`
	e=`eval echo ${E_CFLAGS[$i]}`
	rm -rf out/$a make clean &>/dev/null && make distclean &>/dev/null
	./configure \
		--cross-prefix=$c \
		--sysroot=$s \
		--disable-asm \
		--disable-cli \
		--enable-shared \
		--enable-static \
		--enable-strip \
		--enable-pic \
		--host=arm-linux \
		--prefix=$__OUTPUT/$a \
		--extra-cflags="-fPIC $e" \
		--extra-ldflags="-shared" &>/dev/null
	echo "buiding for $a"
	eval make -j8 $VERBOSE && eval make install $VERBOSE
done

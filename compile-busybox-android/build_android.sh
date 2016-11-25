#!/bin/bash

# Helper script for build busybox for android
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

VERBOSE="&>/dev/null"

case $OSTYPE in
	*darwin*)
		export LC_ALL=C # set for sed
		;;
	*linux*)
		;;
	*) echo "uknown system"
		;;
esac

which 'git' &>/dev/null || {
    printf '\e[31mgit not installed.\e[30m\n'
	exit 1
}

function check_busybox_source()
{
	[ -d busybox ] && {
	    git pull --recurse-submodules
		return
	}
	printf '\e[32mcheck busybox source from official repository\e[30m\n'
	git submodule add 'https://git.busybox.net/busybox' busybox
}

check_busybox_source

if [ -z $ANDROID_NDK_ROOT ];then
	echo "ANDROID_NDK_ROOT not set"
	exit 1
fi

function clean()
{
	eval make clean $VERBOSE
	make mrproper &>/dev/null
	return 0
}

function prepare_config()
{
	cp -vf ../$1 configs/
	eval make $1 $VERBOSE
	if [ "$OSTYPE" == "darwin" ];then
		sed -i '' 's#ANDROID_NDK_ROOT#'"${ANDROID_NDK_ROOT}"'#' .config
	else
		sed -i 's#ANDROID_NDK_ROOT#'"${ANDROID_NDK_ROOT}"'#' .config
	fi
	rm -v configs/$1
}

cd busybox

clean
echo "Build for armeabi with android-9"
prepare_config android_ndk_r10e_android_9_armeabi_defconfig
eval make -j8 $VERBOSE
mkdir -p ../out/armeabi
cp -vf busybox ../out/armeabi/

clean
echo "Build for arm64-v8a with android-21"
prepare_config android_ndk_r10e_android_21_arm64-v8a_defconfig
eval make -j8 $VERBOSE
mkdir -p ../out/arm64-v8a
cp -vf busybox ../out/arm64-v8a/

exit 0

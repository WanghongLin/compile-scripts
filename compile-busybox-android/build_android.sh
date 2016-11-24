#!/bin/bash

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
	cp -vf custom/$1 configs/
	eval make $1 $VERBOSE
	if [ "$OSTYPE" == "darwin" ];then
		sed -i '' 's#ANDROID_NDK_ROOT#'"${ANDROID_NDK_ROOT}"'#' .config
	else
		sed -i 's#ANDROID_NDK_ROOT#'"${ANDROID_NDK_ROOT}"'#' .config
	fi
	rm -v configs/$1
}

clean
echo "Build for armeabi with android-9"
prepare_config android_ndk_r10e_android_9_armeabi_defconfig
eval make -j8 $VERBOSE
mkdir -p custom/armeabi
cp -vf busybox custom/armeabi/

clean
echo "Build for arm64-v8a with android-21"
prepare_config android_ndk_r10e_android_21_arm64-v8a_defconfig
eval make -j8 $VERBOSE
mkdir -p custom/arm64-v8a
cp -vf busybox custom/arm64-v8a/

exit 0

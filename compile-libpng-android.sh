#!/bin/bash
#
# A script to build libpng for Android
#

mkdir -p compile-libpng-android

pushd .

cd compile-libpng-android

_tar_libpng=libpng-1.6.29.tar.xz
_tar_zlib=zlib-1.2.11.tar.gz

curl -sL https://nchc.dl.sourceforge.net/project/libpng/libpng16/1.6.29/libpng-1.6.29.tar.xz -o $_tar_libpng
curl -sL http://zlib.net/zlib-1.2.11.tar.gz -o $_tar_zlib
curl -sL https://raw.githubusercontent.com/WanghongLin/generate-android-mk/master/generate_android_mk.py -o generate_android_mk.py

mkdir -p jni

tar -C jni -Jxvf $_tar_libpng
tar -C jni -zxvf $_tar_zlib

pushd .
cd jni/zlib-1.2.11
python ../../generate_android_mk.py -t static -m libz -s . >> Android.mk
popd

pushd .
cd jni/libpng-1.6.29
python ../../generate_android_mk.py -t static -r -s . -e '(contrib|pngtest|intel|mips|powerpc|scripts|example.c)' -m libpng -D libz >> Android.mk
echo 'include $(CLEAR_VARS)' >> Android.mk
echo 'LOCAL_MODULE := pngtest' >> Android.mk
echo 'LOCAL_STATIC_LIBRARIES := libpng libz' >> Android.mk
echo 'LOCAL_SRC_FILES := ./pngtest.c' >> Android.mk
echo 'include $(BUILD_EXECUTABLE)' >> Android.mk
make -f scripts/pnglibconf.mak
gsed -i 's/^\(.*error[ \t]\+ZLIB_VERNUM.*\)$/\/\/\1/' pngpriv.h
popd

echo 'include $(call all-subdir-makefiles)' >> jni/Android.mk
echo 'APP_PLATFORM := android-16' >> jni/Application.mk

# invoke the build process
# change your device type arm64-v8a
ndk-build && {
    adb push libs/arm64-v8a/pngtest /data/local/tmp/
	adb push jni/libpng-1.6.29/pngtest.png /data/local/tmp/
	adb shell 'cd /data/local/tmp/;./pngtest'
}

popd

#!/bin/bash
# A script to build ffmpeg with many external libraries support
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

export NUM_OF_CPUS=$(cat /proc/cpuinfo |grep processor |wc -l)

FFMPEG_ROOT=`pwd`
export EXTERNAL_ROOT=`pwd`/external
export EXTERNAL_OUT=$EXTERNAL_ROOT/out
export PATH=$EXTERNAL_OUT/bin:$PATH
rm -rf $EXTERNAL_OUT/out

function check_local()
{
	name=$1
	repo_type=$2
	repo_url=$3

	if [ $repo_type == "git" ];then
		repo_cmd="git clone"
	elif [ $repo_type == "svn" ];then
		repo_cmd="svn co"
	elif [ $repo_type == "hg" ];then
		repo_cmd="hg clone"
	elif [ $repo_type == "wget" ];then
		repo_cmd="wget"
	else
		printf "unknown repo type $repo_type"
		exit
	fi

	if [ $repo_type == "wget" ];then
		[ ! -f ${EXTERNAL_ROOT}/$name ] && eval "$repo_cmd -O ${EXTERNAL_ROOT}/${name} $repo_url" || \
			printf "Checking external ${EXTERNAL_ROOT}/${name} ok\n"
		if [[ $name =~ .*\.tar\.gz ]];then
			dirname=${name%%.tar.*}
			extract_cmd="tar zxvf"
		elif [[ $name =~ .*\.tar\.xz ]];then
			dirname=${name%%.tar.*}
			extract_cmd="tar Jxvf"
		elif [[ $name =~ .*\.zip ]];then
			dirname=${name%.*}
			extract_cmd="unzip"
		else
			printf "unknown file type for $name\n"
			exit 0
		fi

		[ ! -d ${EXTERNAL_ROOT}/${dirname} ] && eval "$extract_cmd ${EXTERNAL_ROOT}/${name} -C ${EXTERNAL_ROOT}" || \
			printf "Extract external ${EXTERNAL_ROOT}/${name} done\n"
	else
		[ ! -d ${EXTERNAL_ROOT}/$name ] && eval "$repo_cmd $repo_url ${EXTERNAL_ROOT}/${name}" || \
			printf "Checking external ${EXTERNAL_ROOT}/${name} ok\n"
	fi
}

function build_normal()
{
	target=$1
	shift
	pushd .
	cd $target

	export CFLAGS="-fPIC"
	if [[ ! -f ./autogen.sh && ! -f ./configure ]];then
		printf "Cound not configure $target\n"
		exit 0
	else
		[ -f ./autogen.sh ] && ./autogen.sh
		[ -f ./configure ] && ./configure --prefix=${EXTERNAL_OUT} "$@"
		make -j${NUM_OF_CPUS}
		make install
	fi

	popd
}

function build_cmake()
{
	cmake_target=$1
	cmake_source_dir=$2
	shift
	pushd .

	cd $cmake_target
	cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=${EXTERNAL_OUT} ${cmake_source_dir}
	make -j${NUM_OF_CPUS}
	make install

	popd
}

function build_custom()
{
	pushd .
	cd $1
	shift
	eval "$@"
	popd
}

function install_nasm_for_x264()
{
	printf "Install nasm 2.13.01 for x264 asm build\n"
	check_local nasm-2.13.01.tar.xz wget 'http://www.nasm.us/pub/nasm/releasebuilds/2.13.01/nasm-2.13.01.tar.xz'
	build_normal $EXTERNAL_ROOT/nasm-2.13.01 "--enable-shared=no"
}

which nasm && {
	nasm_version=$(which nasm >/dev/null 2>&1 && nasm -version |cut -d' ' -f3 |sed 's/\.//g')
	if [ $nasm_version -lt 21301 ];then
		install_nasm_for_x264
	fi
} || install_nasm_for_x264


check_local opus git 'https://github.com/xiph/opus'
check_local x264 git 'http://git.videolan.org/git/x264.git'
check_local fdk-aac-0.1.5.tar.gz wget 'https://sourceforge.net/projects/opencore-amr/files/fdk-aac/fdk-aac-0.1.5.tar.gz/download'
check_local lame-3.99.5.tar.gz wget 'https://sourceforge.net/projects/lame/files/lame/3.99/lame-3.99.5.tar.gz/download'
check_local opencore-amr-0.1.5.tar.gz wget 'https://sourceforge.net/projects/opencore-amr/files/opencore-amr/opencore-amr-0.1.5.tar.gz/download'
check_local vo-amrwbenc-0.1.3.tar.gz wget 'https://sourceforge.net/projects/opencore-amr/files/vo-amrwbenc/vo-amrwbenc-0.1.3.tar.gz/download'
check_local libwebp git 'https://github.com/webmproject/libwebp'
check_local libvpx git 'https://github.com/webmproject/libvpx'
check_local speex git 'https://git.xiph.org/speex.git'
check_local ogg git 'https://git.xiph.org/ogg.git'
check_local theora git 'https://git.xiph.org/theora.git'
check_local vorbis git 'https://git.xiph.org/vorbis.git'
check_local twolame-0.3.13.tar.gz wget 'http://downloads.sourceforge.net/twolame/twolame-0.3.13.tar.gz'
check_local openssl-1.0.2l.tar.gz wget 'https://www.openssl.org/source/openssl-1.0.2l.tar.gz'
check_local rtmpdump git 'git://git.ffmpeg.org/rtmpdump'
check_local openh264 git 'https://github.com/cisco/openh264'
check_local numactl git 'https://github.com/numactl/numactl'
check_local x265 hg 'https://bitbucket.org/multicoreware/x265'

build_normal $EXTERNAL_ROOT/opus "--enable-shared=no"
build_normal $EXTERNAL_ROOT/x264 "--enable-static"
build_normal $EXTERNAL_ROOT/fdk-aac-0.1.5 "--enable-shared=no"
build_normal $EXTERNAL_ROOT/lame-3.99.5 "--enable-shared=no"
build_normal $EXTERNAL_ROOT/opencore-amr-0.1.5 "--enable-shared=no"
build_normal $EXTERNAL_ROOT/vo-amrwbenc-0.1.3 "--enable-shared=no"
build_normal $EXTERNAL_ROOT/libwebp "--enable-shared=no"
build_normal $EXTERNAL_ROOT/libvpx "--enable-pic"
build_normal $EXTERNAL_ROOT/speex "--enable-shared=no"
build_normal $EXTERNAL_ROOT/ogg "--enable-shared=no"
build_normal $EXTERNAL_ROOT/theora "--enable-shared=no"
build_normal $EXTERNAL_ROOT/vorbis "--enable-shared=no"
build_normal $EXTERNAL_ROOT/twolame-0.3.13 "--enable-shared=no"
build_custom $EXTERNAL_ROOT/openssl-1.0.2l "./Configure no-shared --prefix=$EXTERNAL_OUT linux-x86_64 && make -j$NUM_OF_CPUS && make install_sw"
build_custom $EXTERNAL_ROOT/rtmpdump "make SHARED=no prefix=$EXTERNAL_OUT -j5 install"
build_custom $EXTERNAL_ROOT/openh264 "make PREFIX=$EXTERNAL_OUT install-static -j5"
build_normal $EXTERNAL_ROOT/numactl "--enable-shared=no"
build_cmake $EXTERNAL_ROOT/x265/build/linux "-DENABLE_SHARED=OFF ../../source"

EXTRA_LIBS=
function add_extra_libs()
{
	EXTRA_LIBS="$EXTRA_LIBS $@"
}

# x265 need stdc++ and libnuma
add_extra_libs '-lstdc++ -Wl,-Bstatic -lnuma -Wl,-Bdynamic'

export PKG_CONFIG_PATH=$EXTERNAL_OUT/lib/pkgconfig:$PKG_CONFIG_PATH

make clean && make distclean
find ./compat -name "*.[do]" -delete
./configure --prefix=$HOME/Applications/ffmpeg \
	--enable-gpl \
	--enable-libx264 \
	--enable-libx265 \
	--enable-libwebp \
	--enable-libopus \
	--enable-libfdk-aac \
	--enable-libmp3lame \
	--enable-libopencore-amrnb \
	--enable-libopencore-amrwb \
	--enable-libvo-amrwbenc \
	--enable-libspeex \
	--enable-libvpx \
	--enable-avresample \
	--enable-openssl \
	--enable-librtmp \
	--enable-libtheora \
	--enable-libvorbis \
	--enable-libtwolame \
	--enable-libopenh264 \
	--enable-nonfree \
	--enable-version3 \
	--enable-pic \
	--disable-doc \
	--extra-cflags="-I$EXTERNAL_OUT/include -fPIC" \
	--extra-ldflags="-L$EXTERNAL_OUT/lib -Wl,-Bsymbolic" \
	--extra-libs="-ldl $EXTRA_LIBS"

make -j5 && make install

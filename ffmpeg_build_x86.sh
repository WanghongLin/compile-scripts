#!/bin/bash


X264_HOME=/Users/wanghong/Developments/x264
LAME_INSTALL_DIR=/Users/wanghong/Stalagmite/lame-3.99.5
VORBIS_INSTALL_DIR=/Users/wanghong/Developments/vorbis/out
OGG_INSTALL_DIR=/Users/wanghong/Developments/libogg-1.3.2/out
OPENCORE_AMR_INSTALL_DIR=/Users/wanghong/Stalagmite/opencore-amr
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/Users/wanghong/Developments/libwebp-ndk/jni/out/lib/pkgconfig:/Users/wanghong/Developments/libvpx-1.4.0/out/lib/pkgconfig:/Users/wanghong/Developments/vorbis/out/lib/pkgconfig:/Users/wanghong/Developments/libogg-1.3.2/out/lib/pkgconfig

(cd ${X264_HOME} && make clean &>/dev/null && make distclean &>/dev/null &&
	./configure --disable-cli --enable-static --enable-pic &>/dev/null &&
	make -j10 &>/dev/null)

make clean &>/dev/null && make distclean &>/dev/null && find compat -name "*.[od]" -delete

./configure --enable-shared \
	--disable-static \
	--enable-gpl \
	--enable-libx264 \
	--enable-libwebp \
	--enable-libmp3lame \
	--enable-libvpx \
	--enable-libvorbis \
	--enable-libopencore-amrnb \
	--enable-libopencore-amrwb \
	--enable-opencl \
	--enable-version3 \
	--extra-cflags="-I../x264 -I$LAME_INSTALL_DIR/include -I$VORBIS_INSTALL_DIR/include -I$OGG_INSTALL_DIR/include -I$OPENCORE_AMR_INSTALL_DIR/include" \
	--extra-ldflags="-L../x264 -L$LAME_INSTALL_DIR/lib -L$VORBIS_INSTALL_DIR/lib -L$OGG_INSTALL_DIR/lib -L$OPENCORE_AMR_INSTALL_DIR/lib" \
	--prefix=/Users/wanghong/Stalagmite/ffmpeg

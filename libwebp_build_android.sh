#!/bin/bash

# Simple script to build libwebp for Android used in FFmpeg project
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

echo "APP_BUILD_SCRIPT = $(readlink -f Android.mk)" > Application.mk
export NDK_PROJECT_PATH=`pwd`
ndk-build NDK_APPLICATION_MK=$(readlink -f Application.mk) -j4
rm Application.mk

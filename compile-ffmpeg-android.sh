#! /usr/bin/env bash
#
# Copyright (C) 2013-2014 Bilibili
# Copyright (C) 2013-2014 Zhang Rui <bbcallen@gmail.com>
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
#

#----------
# modify for your build tool
set -e

# 由于目前设备基本都是电脑64位 手机64位 所以这里脚本默认只支持 arm64 x86_64两个平台
# FF_ALL_ARCHS="armv5 armv7a arm64 i386 x86_64"
FF_ALL_ARCHS="armv7a arm64"
# 编译的API级别 (最小5.0以上系统)
export FF_ANDROID_API=21
# 根据实际情况填写ndk路径，这里采用ndk-r20版本 进行本次编译
export NDK_PATH=/Users/apple/devoloper/mine/android/android-ndk-r20
#export NDK_PATH=/Users/apple/Library/Android/sdk/ndk-bundle
# 要和自己的ndk中的对应，再NDK_PATH下的toolchains目录下查看，比如aarch64-linux-android-4.9后面的是4.9，这里就写4.9
export FF_CC_VER=4.9

# 是否将这些外部库添加进去;如果不添加 则将对应的值改为FALSE即可；默认添加2个库
export lIBS=(x264 fdk-aac mp3lame)
export LIBFLAGS=(TRUE TRUE TRUE)

#----------
UNI_BUILD_ROOT=`pwd`
FF_TARGET=$1

# 配置外部库
config_external_lib()
{
    for(( i=0;i<${#lIBS[@]};i++)) 
    do
        #${#array[@]}获取数组长度用于循环
        lib=${lIBS[i]};
        FF_ARCH=$1
        FF_BUILD_NAME=$lib-$FF_ARCH
        FFMPEG_DEP_LIB=$UNI_BUILD_ROOT/android/build/$FF_BUILD_NAME/lib

        if [[ ${LIBFLAGS[i]} == "TRUE" ]]; then
            if [ ! -f "${FFMPEG_DEP_LIB}/lib$lib.a" ]; then
                # 编译
                . ./android/do-compile-$lib.sh $FF_ARCH
            fi
#        else
#            if [ -f "${FFMPEG_DEP_LIB}/lib$lib.a" -o  -f "${FFMPEG_DEP_LIB}/lib$lib.so" ]; then
#                # 删除 该库
#                rm "${FFMPEG_DEP_LIB}/lib$lib.a"
#                rm "${FFMPEG_DEP_LIB}/lib$lib.so"
#            fi
        fi
    done;
}

# 命令开始执行处----------
if [ "$FF_TARGET" = "armv7a" -o "$FF_TARGET" = "arm64" -o "$FF_TARGET" = "x86_64" ]; then
    
    # 开始之前先检查fork的源代码是否存在
    if [ ! -d android/forksource ]; then
        . ./compile-init.sh ios "offline"
    fi
    
    # 清除之前编译的
    rm -rf android/build/ffmpeg-*
    
    # 先编译外部库
    config_external_lib $FF_TARGET
    
    # 最后编译ffmpeg
    . ./android/do-compile-ffmpeg.sh $FF_TARGET
    
elif [ "$FF_TARGET" = "all" ]; then
    # 开始之前先检查fork的源代码是否存在
    if [ ! -d android/forksource ]; then
        . ./compile-init.sh ios "offline"
    fi
    
    # 清除之前编译的
    rm -rf android/build/ffmpeg-*
    
    for ARCH in $FF_ALL_ARCHS
    do
        # 先编译外部库
        config_external_lib $ARCH
        
        # 最后编译ffmpeg
        . ./android/do-compile-ffmpeg.sh $ARCH
    done

elif [ "$FF_TARGET" = "check" ]; then
    # 分支下必须要有语句 否则出错
    echo "check"
elif [ "$FF_TARGET" == "reset" ]; then
    # 重新拉取所有代码
    echo "....repull all source...."
    . ./init-config.sh android "offline"
elif [ "$FF_TARGET" = "clean" ]; then

    echo "=================="
    for ARCH in $FF_ALL_ARCHS
    do
        echo "clean ffmpeg-$ARCH"
        echo "=================="
        cd android/forksource/ffmpeg-$ARCH && git clean -xdf && cd -
        cd android/forksource/x264-$ARCH && git clean -xdf && cd -
        cd android/forksource/mp3lame-$ARCH && make clean && cd -
        cd android/forksource/fdk-aac-$ARCH && make clean && cd -
    done
    echo "clean build cache"
    echo "================="
    rm -rf android/ffmpeg-*
    echo "clean success"
else
    echo "Usage:"
    echo "  compile-ffmpeg.sh armv7|arm64|x86_64"
    echo "  compile-ffmpeg.sh all"
    echo "  compile-ffmpeg.sh clean"
    echo "  compile-ffmpeg.sh reset"
    exit 1
fi

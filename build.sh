#!/bin/sh

set -xe

VERSION="0.1.3"
LIBSRCNAME="vo-amrwbenc"

CURRENTPATH=`pwd`

# 解压源代码
mkdir -p "${CURRENTPATH}/src"
tar zxvf ${LIBSRCNAME}-${VERSION}.tar.gz -C "${CURRENTPATH}/src"
cd "${CURRENTPATH}/src/${LIBSRCNAME}-${VERSION}"

# 设置环境变量并创建lib-ios文件夹，后续生成的.a类库都会放在这个文件夹里边
DEST="${CURRENTPATH}/lib-ios"
mkdir -p "${DEST}"

# 编译的类型
ARCHS="armv7 armv7s arm64 i386 x86_64"
# 生成的类库名称
LIBS="libvo-amrwbenc.a"

# 开始编译类库
for arch in $ARCHS; do
  case $arch in arm*)
    IOSV="-miphoneos-version-min=7.0"
    if [ $arch == "arm64" ]
    then
        IOSV="-miphoneos-version-min=7.0"
    fi

    echo "Building for iOS $arch ****************"
    # 编译 $arch 环境的类库（amr类型类型）
    SDKROOT="$(xcrun --sdk iphoneos --show-sdk-path)"
    CC="$(xcrun --sdk iphoneos -f clang)"
    CXX="$(xcrun --sdk iphoneos -f clang++)"
    CPP="$(xcrun -sdk iphonesimulator -f clang++)"
    CFLAGS="-isysroot $SDKROOT -arch $arch $IOSV -isystem $SDKROOT/usr/include -fembed-bitcode"
    CXXFLAGS=$CFLAGS
    CPPFLAGS=$CFLAGS
    export CC CXX CFLAGS CXXFLAGS CPPFLAGS

    ./configure \
    --host=arm-apple-darwin \
    --prefix=$DEST \
    --disable-shared --enable-static
    ;;

  *)
    IOSV="-mios-simulator-version-min=7.0"
    echo "Building for iOS $arch*****************"
    # 编译 $arch 环境的类库（其他类型类型）
    SDKROOT=`xcodebuild -version -sdk iphonesimulator Path`
    CC="$(xcrun -sdk iphoneos -f clang)"
    CXX="$(xcrun -sdk iphonesimulator -f clang++)"
    CPP="$(xcrun -sdk iphonesimulator -f clang++)"
    CFLAGS="-isysroot $SDKROOT -arch $arch $IOSV -isystem $SDKROOT/usr/include -fembed-bitcode"
    CXXFLAGS=$CFLAGS
    CPPFLAGS=$CFLAGS
    export CC CXX CFLAGS CXXFLAGS CPPFLAGS
    ./configure \
    --prefix=$DEST \
    --disable-shared
    ;;
  esac

  make > /dev/null
  make install      # 将编译成功的可执行文件安装到指定目录中
  make clean        # 清除上次的make命令所产生的object文件（后缀为“.o”的文件）及可执行文件。

  # 清除多余的文件
  for i in $LIBS; do
  mv $DEST/lib/$i $DEST/lib/$i.$arch
  done
done

# 制作通用静态库
# http://blog.csdn.net/cuiweijie3/article/details/8671240

for i in $LIBS; do
  input=""
  for arch in $ARCHS; do
    input="$input $DEST/lib/$i.$arch"
  done
  lipo -create -output $DEST/lib/$i $input
done

#!/bin/bash
set -e
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Version definitions
source $BASE_DIR/version.sh

mkdir -p "$BASE_DIR/.downloads"
mkdir -p "$BASE_DIR/.extracttmp"
download_packages gcc binutils kernel glibc mpfr gmp mpc

# Enter GCC source directory
cd "$BASE_DIR/.extracttmp/gcc-${GCC_VERSION}"
# Extract and rename GCC internal dependencies
for name in "${!gcc_components[@]}"; do
  src_dir="${gcc_components[$name]}"
  tarball="$BASE_DIR/.downloads/${src_dir}.tar.gz"
  
  if [[ -d "$name" ]]; then
    echo "Directory $name already exists inside gcc source, skipping."
  else
    echo "Extracting $tarball into $name..."
    tar -xf "$tarball" -C "$BASE_DIR/.extracttmp/gcc-${GCC_VERSION}"
    mv "$src_dir" "$name"
  fi
done

echo "All unzip tasks completed successfully."

# binutils
cd "$BASE_DIR/.extracttmp/binutils-${BINUTILS_VERSION}"
echo "Building binutils."
mkdir -v build
cd build
../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-new-dtags  \
             --enable-default-hash-style=gnu
make && make install

# gcc
cd "$BASE_DIR/.extracttmp/gcc-${GCC_VERSION}"
echo "Building gcc"
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac
mkdir -v build
cd build
../configure                  \
    --target=$LFS_TGT         \
    --prefix=$LFS/tools       \
    --with-glibc-version=2.41 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++
make && make install
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h


# linux headers
cd "$BASE_DIR/.extracttmp/linux-${KERNEL_VERSION}"
make INSTALL_HDR_PATH=$LFS/usr headers_install

# glibc
echo "Building glibc"
cd "$BASE_DIR/.extracttmp/glibc-${GLIBC_VERSION}"
case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac
mkdir -v build
cd build
echo "rootsbindir=/usr/sbin" > configparms
../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=5.4                \
      --with-headers=$LFS/usr/include    \
      --disable-nscd                     \
      libc_cv_slibdir=/usr/lib

make && make DESTDIR=$LFS install
sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd


cd "$BASE_DIR/.extracttmp/gcc-${GCC_VERSION}"
echo "Building libstdc++"
rm -rf build
mkdir -v build
cd build
../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0
make && make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la

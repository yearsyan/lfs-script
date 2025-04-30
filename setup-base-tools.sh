#!/bin/bash

set -e

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $BASE_DIR/version.sh

mkdir -p "$BASE_DIR/.downloads"
mkdir -p "$BASE_DIR/.extracttmp"
download_packages m4 ncurses bash coreutils diffutils file findutils gawk grep gzip make patch sed tar xz binutils gcc mpfr gmp mpc

cd "$BASE_DIR/.extracttmp/m4-${M4_VERSION}"
echo "Building m4"
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make && make DESTDIR=$LFS install

cd "$BASE_DIR/.extracttmp/ncurses-${NCURSES_VERSION}"
echo "Building ncurses"
mkdir build
pushd build
  ../configure AWK=gawk
  make -C include
  make -C progs tic
popd
./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            AWK=gawk
make && make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -svf libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h


cd "$BASE_DIR/.extracttmp/bash-${BASH_VERSION}"
echo "Building bash"
./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc
make && make DESTDIR=$LFS install
mkdir -p $LFS/bin
ln -svf bash $LFS/bin/sh

cd "$BASE_DIR/.extracttmp/coreutils-${COREUTILS_VERSION}"
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime
make && make DESTDIR=$LFS install
mkdir -p $LFS/usr/sbin
mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8

cd "$BASE_DIR/.extracttmp/diffutils-${DIFFUTILS_VERSION}"
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make && make DESTDIR=$LFS install

cd "$BASE_DIR/.extracttmp/file-${FILE_VERSION}"
echo "Building file"
mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la

cd "$BASE_DIR/.extracttmp/findutils-${FINDUTILS_VERSION}"
echo "Building findutils"
./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)
make && make DESTDIR=$LFS install


cd "$BASE_DIR/.extracttmp/gawk-${GAWK_VERSION}"
echo "Building gawk"
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make && make DESTDIR=$LFS install

cd "$BASE_DIR/.extracttmp/grep-${GREP_VERSION}"
echo "Building grep"
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make && make DESTDIR=$LFS install

cd "$BASE_DIR/.extracttmp/gzip-${GZIP_VERSION}"
echo "Building gzip"
./configure --prefix=/usr --host=$LFS_TGT
make && make DESTDIR=$LFS install

cd "$BASE_DIR/.extracttmp/make-${MAKE_VERSION}"
echo "Building make"
./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make && make DESTDIR=$LFS install

cd "$BASE_DIR/.extracttmp/patch-${PATCH_VERSION}"
echo "Building patch"
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make && make DESTDIR=$LFS install

cd "$BASE_DIR/.extracttmp/sed-${SED_VERSION}"
echo "Building sed"
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make && make DESTDIR=$LFS install

cd "$BASE_DIR/.extracttmp/tar-${TAR_VERSION}"
echo "Building tar"
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)
make && make DESTDIR=$LFS install

cd "$BASE_DIR/.extracttmp/xz-${XZ_VERSION}"
echo "Building xz"
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.6.4
make && make DESTDIR=$LFS install
rm -v $LFS/usr/lib/liblzma.la 

# binutils twice
cd "$BASE_DIR/.extracttmp/binutils-${BINUTILS_VERSION}"
sed '6031s/$add_dir//' -i ltmain.sh
echo "Building binutils"
mkdir build
cd build
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu
make && make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

# GCC twice
cd "$BASE_DIR/.extracttmp/gcc-${GCC_VERSION}"
# Extract and rename GCC internal dependencies
for name in "${!gcc_components[@]}"; do
  src_dir="${gcc_components[$name]}"
  tarball="$BASE_DIR/.downloads/${src_dir}.tar.gz"
  
  if [[ -d "$name" ]]; then
    echo "Directory $name already exists inside gcc source, skipping."
  else
    echo "Extracting $tarball into $name..."
    tar -xf "$tarball" -C $(pwd)
    mv "$src_dir" "$name"
  fi
done

# lib
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir build
cd build
echo "Building gcc"
../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --target=$LFS_TGT                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$LFS                      \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --enable-languages=c,c++
make && make DESTDIR=$LFS install
ln -svf gcc $LFS/usr/bin/cc
# GCC twice end
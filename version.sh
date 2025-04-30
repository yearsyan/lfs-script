: "${BASE_DIR?Error: BASE_DIR is not set}"

# Version definitions
M4_VERSION="1.4.19"
NCURSES_VERSION="6.5"
BASH_VERSION="5.2.37"
COREUTILS_VERSION="9.6"
DIFFUTILS_VERSION="3.11"
FILE_VERSION="5.46"
FINDUTILS_VERSION="4.10.0"
GAWK_VERSION="5.3.1"
GREP_VERSION="3.11"
GZIP_VERSION="1.13"
MAKE_VERSION="4.4.1"
PATCH_VERSION="2.7.6"
SED_VERSION="4.9"
TAR_VERSION="1.35"
XZ_VERSION="5.6.4"
GCC_VERSION="14.2.0"
BINUTILS_VERSION="2.44"
MPFR_VERSION="4.2.1"
GMP_VERSION="6.3.0"
MPC_VERSION="1.3.1"
KERNEL_VERSION="6.14.4"
GLIBC_VERSION="2.41"
ACL_VERSION="2.3.2"
ATTR_VERSION="2.5.2"
AUTOCONF_VERSION="2.72"
AUTOMAKE_VERSION="1.17"
BC_VERSION="7.0.3"
BISON_VERSION="3.8.2"
BZIP2_VERSION="1.0.8"
CHECK_VERSION="0.15.2"
DEJAGNU_VERSION="1.6.3"
E2FSPROGS_VERSION="1.47.2"
ELFUTILS_VERSION="0.192"
EXPAT_VERSION="2.6.4"
EXPECT_VERSION="5.45.4"
FLEX_VERSION="2.6.4"
FLIT_CORE_VERSION="3.11.0"
GDBM_VERSION="1.24"
GETTEXT_VERSION="0.24"
GPERF_VERSION="3.1"
GROFF_VERSION="1.23.0"
INETUTILS_VERSION="2.6"
INTLTOOL_VERSION="0.51.0"
IPROUTE2_VERSION="6.13.0"
JINJA2_VERSION="3.1.5"
KBD_VERSION="2.7.1"
KMOD_VERSION="34"
LESS_VERSION="668"
LIBCAP_VERSION="2.73"
LIBFFI_VERSION="3.4.7"
LIBPIPELINE_VERSION="1.5.8"
LIBTOOL_VERSION="2.5.4"
LIBXCRYPT_VERSION="4.4.38"
LZ4_VERSION="1.10.0"
MAN_DB_VERSION="2.13.0"
MARKUPSAFE_VERSION="3.0.2"
MESON_VERSION="1.7.0"
NINJA_VERSION="1.12.1"
OPENSSL_VERSION="3.4.1"
PERL_VERSION="5.40.1"
PKGCONF_VERSION="2.3.0"
PROCPS_NG_VERSION="4.0.5"
PSMISC_VERSION="23.7"
PYTHON_VERSION="3.13.2"
READLINE_VERSION="8.2.13"
SETUPTOOLS_VERSION="75.8.1"
SHADOW_VERSION="4.17.3"
SYSKLOGD_VERSION="2.7.0"
SYSVINIT_VERSION="3.14"
TCL_VERSION="8.6.16"
TEXINFO_VERSION="7.2"
UTIL_LINUX_VERSION="2.40.4"
VIM_VERSION="9.1.1166"
WHEEL_VERSION="0.45.1"
XML_PARSER_VERSION="2.47"
ZLIB_VERSION="1.3.1"
ZSTD_VERSION="1.5.7"


declare -A downloads=(
  [m4]="https://ftp.gnu.org/gnu/m4/m4-${M4_VERSION}.tar.gz"
  [ncurses]="https://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"
  [bash]="https://ftp.gnu.org/gnu/bash/bash-${BASH_VERSION}.tar.gz"
  [coreutils]="https://ftp.gnu.org/gnu/coreutils/coreutils-${COREUTILS_VERSION}.tar.xz"
  [diffutils]="https://ftp.gnu.org/gnu/diffutils/diffutils-${DIFFUTILS_VERSION}.tar.xz"
  [file]="https://astron.com/pub/file/file-${FILE_VERSION}.tar.gz"
  [findutils]="https://ftp.gnu.org/gnu/findutils/findutils-${FINDUTILS_VERSION}.tar.xz"
  [gawk]="https://ftp.gnu.org/gnu/gawk/gawk-${GAWK_VERSION}.tar.xz"
  [grep]="https://ftp.gnu.org/gnu/grep/grep-${GREP_VERSION}.tar.xz"
  [gzip]="https://ftp.gnu.org/gnu/gzip/gzip-${GZIP_VERSION}.tar.xz"
  [make]="https://ftp.gnu.org/gnu/make/make-${MAKE_VERSION}.tar.gz"
  [patch]="https://ftp.gnu.org/gnu/patch/patch-${PATCH_VERSION}.tar.xz"
  [sed]="https://ftp.gnu.org/gnu/sed/sed-${SED_VERSION}.tar.xz"
  [tar]="https://ftp.gnu.org/gnu/tar/tar-${TAR_VERSION}.tar.xz"
  [xz]="https://github.com/tukaani-project/xz/releases/download/v${XZ_VERSION}/xz-${XZ_VERSION}.tar.gz"
  [binutils]="https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz"
  [gcc]="https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz"
  [mpfr]="https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.gz"
  [gmp]="https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.gz"
  [mpc]="https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz"
  [kernel]="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"
  [glibc]="https://ftp.gnu.org/gnu/glibc/glibc-${GLIBC_VERSION}.tar.xz"
)

declare -A gcc_components=(
  ["mpfr"]="mpfr-${MPFR_VERSION}"
  ["gmp"]="gmp-${GMP_VERSION}"
  ["mpc"]="mpc-${MPC_VERSION}"
)

download_packages() {
  local keys=("$@")
  local failed=0
  local pids=()

  for key in "${keys[@]}"; do
    (
      url="${downloads[$key]}"
      filename="${url##*/}"
      dirname="${filename%.tar.*}"
      
      echo "Download $key from $url"

      # Download
      if [ ! -f "$BASE_DIR/.downloads/$filename" ]; then
        wget -q --show-progress -O "$BASE_DIR/.downloads/$filename" "$url" || {
          echo "Failed to download $filename"
          exit 1
        }
      else
        echo "$filename already exists, skipping download."
      fi  

      # Skip extraction if SKIP_EXTRACT is set
      if [ "$SKIP_EXTRACT" != "1" ]; then
        # Remove old dir if exists
        [ -d "$BASE_DIR/.extracttmp/$dirname" ] && rm -rf "$BASE_DIR/.extracttmp/$dirname"

        # Extract
        case "$filename" in
          *.tar.gz|*.tgz)  tar -xzf "$BASE_DIR/.downloads/$filename" -C "$BASE_DIR/.extracttmp" || exit 1 ;;
          *.tar.xz)        tar -xJf "$BASE_DIR/.downloads/$filename" -C "$BASE_DIR/.extracttmp" || exit 1 ;;
          *.tar.bz2)       tar -xjf "$BASE_DIR/.downloads/$filename" -C "$BASE_DIR/.extracttmp" || exit 1 ;;
          *)               echo "Unknown archive type: $filename"; exit 1 ;;
        esac
        echo "$key extracted successfully."
      else
        echo "Skipping extraction for $filename due to SKIP_EXTRACT=1"
      fi

      echo "$key finished successfully."
    ) &
    pids+=($!)
  done

  # Wait for all parallel tasks
  for pid in "${pids[@]}"; do
    wait "$pid" || failed=1
  done

  if [ $failed -ne 0 ]; then
    echo "One or more downloads/extractions failed. Exiting."
    exit 1
  else
    echo "All downloads and extractions completed successfully."
  fi
}

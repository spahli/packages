#!/bin/bash

######################################################################
# Copyright (c) 2019 Claudio André <claudioandre.br at gmail.com>
#
# This program comes with ABSOLUTELY NO WARRANTY; express or implied.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, as expressed in version 2, seen at
# http://www.gnu.org/licenses/gpl-2.0.html
######################################################################

# Required defines
TEST=';full;extra;' # Controls how the test will happen
arch=$(uname -m)
JTR_BIN='../run/john'
JTR_CL="$JTR_BIN"

# Build options (system wide, disable checks, etc.)
SYSTEM_WIDE='--with-systemwide'
X86_REGULAR="--disable-native-tests $SYSTEM_WIDE"
X86_NO_OPENMP="--disable-native-tests $SYSTEM_WIDE --disable-openmp"

OTHER_REGULAR="$SYSTEM_WIDE"
OTHER_NO_OPENMP="$SYSTEM_WIDE --disable-openmp"

# Get JtR source code and adjust it to create a SNAP package
git clone --depth 10 https://github.com/magnumripper/JohnTheRipper.git tmp
cp -r tmp/. .

# We are in packages folder, change to JtR folder
cd src

wget https://raw.githubusercontent.com/claudioandre-br/packages/master/patches/0001-Handle-self-confined-system-wide-build.patch
patch < 0001-Handle-self-confined-system-wide-build.patch

# Set package version
git rev-parse --short HEAD 2>/dev/null > ../../../../My_VERSION.TXT

# Force CFLAGS with -O2
export CFLAGS="-O2 $CFLAGS"

# Show environmen information
wget https://raw.githubusercontent.com/claudioandre-br/packages/master/john-the-ripper/tests/show_info.sh
source show_info.sh

# Build helper
wget https://raw.githubusercontent.com/claudioandre-br/packages/master/john-the-ripper/tests/run_build.sh
source run_build.sh

echo ""
echo "---------------------------- BUILDING -----------------------------"

if [[ "$arch" == "x86_64" ]]; then
    # Allow an OpenCL build
    sudo apt-get install -y beignet-dev

    # CPU (OMP and extensions fallback)
    ./configure $X86_NO_OPENMP CPPFLAGS="-D_SNAP -D_BOXED" && do_build ../run/john-sse2-non-omp
    ./configure $X86_REGULAR   CPPFLAGS="-D_SNAP -D_BOXED -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-sse2-non-omp\\\"\"" && do_build ../run/john-sse2
    ./configure $X86_NO_OPENMP CPPFLAGS="-D_SNAP -D_BOXED -msse4.1" && do_build ../run/john-sse4-non-omp
    ./configure $X86_REGULAR   CPPFLAGS="-D_SNAP -D_BOXED -msse4.1 -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-sse4-non-omp\\\"\" -DCPU_FALLBACK -DCPU_FALLBACK_BINARY=\"\\\"john-sse2\\\"\"" && do_build ../run/john-sse4
    ./configure $X86_NO_OPENMP CPPFLAGS="-D_SNAP -D_BOXED -mavx" && do_build ../run/john-avx-non-omp
    ./configure $X86_REGULAR   CPPFLAGS="-D_SNAP -D_BOXED -mavx -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-avx-non-omp\\\"\" -DCPU_FALLBACK -DCPU_FALLBACK_BINARY=\"\\\"john-sse4\\\"\"" && do_build ../run/john-avx
    ./configure $X86_NO_OPENMP CPPFLAGS="-D_SNAP -D_BOXED -mxop" && do_build ../run/john-xop-non-omp
    ./configure $X86_REGULAR   CPPFLAGS="-D_SNAP -D_BOXED -mxop -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-xop-non-omp\\\"\" -DCPU_FALLBACK -DCPU_FALLBACK_BINARY=\"\\\"john-avx\\\"\"" && do_build ../run/john-xop
    ./configure $X86_NO_OPENMP CPPFLAGS="-D_SNAP -D_BOXED -mavx2" && do_build ../run/john-non-omp
    ./configure $X86_REGULAR   CPPFLAGS="-D_SNAP -D_BOXED -mavx2 -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-non-omp\\\"\" -DCPU_FALLBACK -DCPU_FALLBACK_BINARY=\"\\\"john-xop\\\"\"" && do_build

    # Install OpenCL kernel code
    make kernel-copy

else
    # Non X86 CPU
    ./configure $OTHER_NO_OPENMP CPPFLAGS="-D_SNAP -D_BOXED" && do_build ../run/john-non-omp
    ./configure $OTHER_REGULAR   CPPFLAGS="-D_SNAP -D_BOXED -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-non-omp\\\"\"" && do_build
fi

# To be able to run testing
sudo apt-get install -y language-pack-en

# "---------------------------- TESTING -----------------------------"
# Allow to test a system wide build
mkdir --parents /snap/john-the-ripper/current/
ln -s $(realpath ../run) /snap/john-the-ripper/current/run

# Adjust the testing environment, import and run some testing
wget https://raw.githubusercontent.com/claudioandre-br/packages/master/john-the-ripper/tests/disable_formats.sh
source disable_formats.sh

wget https://raw.githubusercontent.com/claudioandre-br/packages/master/john-the-ripper/tests/run_tests.sh
source run_tests.sh

wget https://raw.githubusercontent.com/claudioandre-br/packages/master/john-the-ripper/tests/clean_package.sh
source clean_package.sh

# Get the script that computes the package version
wget https://raw.githubusercontent.com/claudioandre-br/packages/master/john-the-ripper/tests/package_version.sh
chmod +x package_version.sh
cp package_version.sh ../../../../package_version.sh

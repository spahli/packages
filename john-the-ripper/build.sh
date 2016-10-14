#!/bin/bash

#snapcraft clean --step build transfer
#snapcraft clean --step build libs
#rm parts/john-the-ripper/build/run/john-*

git clone https://github.com/magnumripper/JohnTheRipper.git tmp
cp -r tmp/. .
wget https://raw.githubusercontent.com/claudioandre/packages/master/john-the-ripper/john-the-ripper.opencl
chmod +x john-the-ripper.opencl
cd src

wget https://raw.githubusercontent.com/claudioandre/packages/master/patches/0001-Handle-self-confined-system-wide-build.patch
patch < 0001-Handle-self-confined-system-wide-build.patch

# CFLAGS is set when regex is build. Harm JtR configure process.
TMP_FLAGS="$CFLAGS"
unset CFLAGS

arch=`uname -m`
text='x'
git_tag=$(git describe --dirty=+ --always 2>/dev/null)

case "$arch" in
    'x86_64')
        text='J1'
        ;;
    'armhf' | 'armv7l')
        text='a1'
        ;;
    'aarch64' | 'arm64')
        text='B1'
        ;;
    'ppc64le' | 'powerpc64le')
        text='P1'
        ;;
esac
# Set package version
sed -i "s/edge/1.8.0-$text-$git_tag/g" ../../../../snapcraft.yaml

if [[ "$arch" == 'x86_64' ]]; then
    # OpenCL (OMP fallback)
    ./configure --disable-native-tests --with-systemwide --disable-openmp CPPFLAGS="$TMP_FLAGS -D_SNAP" && make -s clean && make -s && mv ../run/john ../run/john-opencl-non-omp
    ./configure --disable-native-tests --with-systemwide                  CPPFLAGS="$TMP_FLAGS -D_SNAP -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-opencl-non-omp\\\"\"" && make -s clean && make -s && mv ../run/john ../run/john-opencl

    # CPU (OMP and extensions fallback)
    ./configure --disable-native-tests --disable-opencl --with-systemwide --disable-openmp CPPFLAGS="$TMP_FLAGS -D_SNAP" && make -s clean && make -s && mv ../run/john ../run/john-sse2-non-omp
    ./configure --disable-native-tests --disable-opencl --with-systemwide                  CPPFLAGS="$TMP_FLAGS -D_SNAP -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-sse2-non-omp\\\"\"" && make -s clean && make -s && mv ../run/john ../run/john-sse2
    ./configure --disable-native-tests --disable-opencl --with-systemwide --disable-openmp CPPFLAGS="$TMP_FLAGS -D_SNAP -mavx" && make -s clean && make -s && mv ../run/john ../run/john-avx-non-omp
    ./configure --disable-native-tests --disable-opencl --with-systemwide                  CPPFLAGS="$TMP_FLAGS -D_SNAP -mavx -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-avx-non-omp\\\"\" -DCPU_FALLBACK -DCPU_FALLBACK_BINARY=\"\\\"john-sse2\\\"\"" && make -s clean && make -s && mv ../run/john ../run/john-avx
    ./configure --disable-native-tests --disable-opencl --with-systemwide --disable-openmp CPPFLAGS="$TMP_FLAGS -D_SNAP -mxop" && make -s clean && make -s && mv ../run/john ../run/john-xop-non-omp
    ./configure --disable-native-tests --disable-opencl --with-systemwide                  CPPFLAGS="$TMP_FLAGS -D_SNAP -mxop -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-xop-non-omp\\\"\" -DCPU_FALLBACK -DCPU_FALLBACK_BINARY=\"\\\"john-avx\\\"\"" && make -s clean && make -s && mv ../run/john ../run/john-xop
    ./configure --disable-native-tests --disable-opencl --with-systemwide --disable-openmp CPPFLAGS="$TMP_FLAGS -D_SNAP -mavx2" && make -s clean && make -s && mv ../run/john ../run/john-non-omp
    ./configure --disable-native-tests --disable-opencl --with-systemwide                  CPPFLAGS="$TMP_FLAGS -D_SNAP -mavx2 -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-non-omp\\\"\" -DCPU_FALLBACK -DCPU_FALLBACK_BINARY=\"\\\"john-xop\\\"\"" && make -s clean && make -s
else
    # CPU (OMP and extensions fallback)
    ./configure --disable-native-tests --disable-opencl --with-systemwide --disable-openmp CPPFLAGS="$TMP_FLAGS -D_SNAP" && make -s clean && make -s && mv ../run/john ../run/john-non-omp
    ./configure --disable-native-tests --disable-opencl --with-systemwide                  CPPFLAGS="$TMP_FLAGS -D_SNAP -DOMP_FALLBACK -DOMP_FALLBACK_BINARY=\"\\\"john-non-omp\\\"\"" && make -s clean && make -s

    ln -s ../run/john ../run/john-opencl
fi

# Do some testing
if [[ "$TEST" = "yes" ]]; then
    echo ""
    echo "---------------------------- TESTING -----------------------------"
    ../run/john --list=build-info
    echo "------------------------------------------------------------------"
    ../run/john --stdout --regex='[0-2]password[A-C]'
    echo "------------------------------------------------------------------"
    echo magnum | ../run/john -stdout -stdin -regex='\0[01]'
    echo "------------------------------------------------------------------"
    echo müller | iconv -t cp850 | ../run/john -inp=cp850 -stdout -stdin -regex='\0[01]'
    echo "------------------------------------------------------------------"
    ../run/john -test-full=0 --format=nt
    echo "------------------------------------------------------------------"
    ../run/john -test-full=0 --format=raw-sha256
    echo "------------------------------------------------------------------"
    ../run/john-opencl -test-full=0 --format=sha512crypt-opencl
    echo "------------------------------------------------------------------"
    echo ""
fi

#!/usr/bin/env bash

# based on https://github.com/bioconda/bioconda-recipes/tree/master/recipes/pb-falconc

set -vexu -o pipefail

pushd nim

#  Avoid SYS_Random since glibc < 2.25
echo '-d:nimNoGetRandom' >>config/nim.cfg

# inject compilers
if [[ ${target_platform} =~ linux.* ]]; then

	cat <<'EOF' >>config/nim.cfg
gcc.exe %= "$GCC"
gcc.cpp.exe %= "$GXX"
gcc.linkerexe %= "$GCC"
gcc.options.linker %= "$LDFLAGS -ldl"
gcc.cpp.options.linker %= "$LDFLAGS -ldl"

gcc.options.always %= "$CPPFLAGS $CFLAGS ${gcc.options.always}"
gcc.cpp.options.always %= "$CPPFLAGS $CFLAGS ${gcc.cpp.options.always}"
EOF

else

	cat <<'EOF' >>config/nim.cfg
clang.exe %= "$CLANG"
clang.cpp.exe %= "$CLANGXX"
clang.linkerexe %= "$CLANG"
clang.options.linker %= "$LDFLAGS"
clang.cpp.options.linker %= "$LDFLAGS"

clang.options.always %= "$CPPFLAGS $CFLAGS ${gcc.options.always}"
clang.cpp.options.always %= "$CPPFLAGS $CFLAGS ${gcc.cpp.options.always}"
EOF

fi

./build.sh
bin/nim c koch
./koch boot -d:release
./koch tools

ls -larth
ls -larth bin/
ls -larth lib/
ls -larth config/

./install.sh "${PREFIX}"
cp -f bin/* "${PREFIX}/nim/bin/"
mkdir -p "${PREFIX}/bin"
for binary in "${PREFIX}/nim/bin/"*; do
	ln -s "${binary}" "${PREFIX}/bin/"
done

# NEW: Nim packages installed by conda live in $PREFIX/share/nimble/pkgs2
mkdir -p "${PREFIX}/share/nimble/pkgs2" "${PREFIX}/etc/conda/activate.d" "${PREFIX}/etc/conda/deactivate.d"
touch "${PREFIX}/share/nimble/pkgs2/.keep"
cp "${RECIPE_DIR}/activate.sh" "${PREFIX}/etc/conda/activate.d/nim.sh"
cp "${RECIPE_DIR}/deactivate.sh" "${PREFIX}/etc/conda/deactivate.d/nim.sh"

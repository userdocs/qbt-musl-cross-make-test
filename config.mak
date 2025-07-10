# Optimization Flags
OPTIMIZATION_FLAGS = -O3 -pipe -fdata-sections -ffunction-sections

# Preprocessor Flags
PREPROCESSOR_FLAGS = -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS

# Security Flags
SECURITY_FLAGS = \
    -fstack-clash-protection \
    -fstack-protector-strong \
    -fno-delete-null-pointer-checks \
    -fno-strict-overflow \
    -fno-strict-aliasing \
    -ftrivial-auto-var-init=zero \
    -fexceptions

# Warning Flags
WARNING_FLAGS = -w

# Linker Flags
LINKER_FLAGS = \
    -pthread \
    -Wl,-s \
    -Wl,-O1,--as-needed,--sort-common,-z,noexecstack,-z,now,-z,relro,-z,max-page-size=65536,--no-copy-dt-needed-entries

# Static Linking Flags
STATIC_FLAGS = -static
STATIC_LDFLAGS = -static

# Toolchain Build Flags (for building the toolchain itself statically)
TOOLCHAIN_STATIC_FLAGS = -static -static-libgcc -static-libstdc++

# Compiler configurations
COMMON_CONFIG += --prefix= --libdir=/lib
COMMON_CONFIG += CC="gcc"
COMMON_CONFIG += CXX="g++"
COMMON_CONFIG += CFLAGS="${OPTIMIZATION_FLAGS} ${SECURITY_FLAGS} ${STATIC_FLAGS}"
COMMON_CONFIG += CXXFLAGS="${OPTIMIZATION_FLAGS} ${SECURITY_FLAGS} ${STATIC_FLAGS} ${WARNING_FLAGS}"
COMMON_CONFIG += CPPFLAGS="${PREPROCESSOR_FLAGS} ${WARNING_FLAGS}"
COMMON_CONFIG += LDFLAGS="${LINKER_FLAGS} ${STATIC_LDFLAGS}"

# Host toolchain flags (for building the cross-compiler itself)
COMMON_CONFIG += CFLAGS_FOR_HOST="${OPTIMIZATION_FLAGS} ${SECURITY_FLAGS} ${TOOLCHAIN_STATIC_FLAGS}"
COMMON_CONFIG += CXXFLAGS_FOR_HOST="${OPTIMIZATION_FLAGS} ${SECURITY_FLAGS} ${TOOLCHAIN_STATIC_FLAGS} ${WARNING_FLAGS}"
COMMON_CONFIG += LDFLAGS_FOR_HOST="${LINKER_FLAGS} ${TOOLCHAIN_STATIC_FLAGS}"

# Binutils configuration
BINUTILS_CONFIG += --disable-gprofng
BINUTILS_CONFIG += --enable-default-pie
BINUTILS_CONFIG += --disable-shared
BINUTILS_CONFIG += --enable-static
BINUTILS_CONFIG += --disable-plugins
BINUTILS_CONFIG += --disable-multilib

# GCC configuration
GCC_CONFIG += --disable-bootstrap --disable-assembly --disable-werror
GCC_CONFIG += --disable-multilib --disable-libmudflap --disable-libgomp
GCC_CONFIG += --disable-libsanitizer --disable-gnu-indirect-function
GCC_CONFIG += --disable-libmpx --disable-libatomic
GCC_CONFIG += --enable-tls --enable-default-pie --enable-static-pie
GCC_CONFIG += --enable-pic --disable-shared --enable-static
GCC_CONFIG += --disable-libssp
GCC_CONFIG += --enable-initfini-array
GCC_CONFIG += --enable-libstdcxx-time=rt --enable-libstdcxx-time
GCC_CONFIG += --enable-deterministic-archives
GCC_CONFIG += --enable-libquadmath --enable-libquadmath-support
GCC_CONFIG += --disable-decimal-float
GCC_CONFIG += --with-stage1-ldflags="${TOOLCHAIN_STATIC_FLAGS}"
GCC_CONFIG += --with-boot-ldflags="${TOOLCHAIN_STATIC_FLAGS}"
GCC_CONFIG += --enable-languages=c,c++

# GCC configuration for target - modified by workflow using triples.json
GCC_CONFIG_FOR_TARGET += --enable-default-pie --enable-static-pie --enable-pic --with-pic --disable-shared

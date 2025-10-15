#!/usr/bin/env sh

VERSION=2.12.0
SHA256=1355d81091d13643aed140ba0fe62437c02d9434b44e90975aaefab84c2bf237
ARCH=$(uname -m)
KERNEL=$(uname -s)

error() {
    echo ERROR: "$1" >&2
    exit 1
}

if [ ! -f "v$VERSION.tar.gz" ]; then
  curl -LO "https://github.com/confluentinc/librdkafka/archive/refs/tags/v$VERSION.tar.gz" ||  error "Download failed"
fi

echo "$SHA256 v$VERSION.tar.gz" | sha256sum -c - || error "Checksum didn't match"
tar -xf "v$VERSION.tar.gz" || error "Decompression failed"

cd "librdkafka-$VERSION" || error "Failed to enter source directory"
if [ ! -f "Makefile.config" ]; then
  if [ "$KERNEL" = "Darwin" ]; then
    ./configure --install-deps --source-deps-only --enable-static --enable-zstd --disable-curl --disable-zlib --enable-gssapi --enable-sasl --enable-ssl || error "Failed to configure and compile dependencies"
  elif [ "$KERNEL" = "Linux" ]; then
    ./configure --disable-zstd --disable-curl --disable-zlib --enable-gssapi --enable-sasl --enable-ssl || error "Failed to configure and compile dependencies"
  else
    error "Unknown kernel $KERNEL"
  fi
else
  echo "Already ran ./configure, skipping"
fi

# NOTE: Simply running `make` didn't work, because it got stuck somewhere
make mklove-check || error "Failed to run mklove-check"
make libs || error "Failed to buildlibraries"

mkdir -p "../output/$ARCH" || error "Failed to create output directory"

if [ "$KERNEL" = "Darwin" ]; then
  cp src/librdkafka*.dylib "../output/$ARCH/"
elif [ "$KERNEL" = "Linux" ]; then
  cp src/librdkafka*.so* "../output/$ARCH/"
else
    error "Unknown kernel $KERNEL"
fi


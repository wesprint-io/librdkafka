#!/usr/bin/env sh

VERSION=2.11.0
SHA256=592a823dc7c09ad4ded1bc8f700da6d4e0c88ffaf267815c6f25e7450b9395ca
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
    ./configure --install-deps --source-deps-only --enable-static --enable-zstd --disable-curl --disable-zlib --enable-gssapi --enable-sasl || error "Failed to configure and compile dependencies"
  elif [ "$KERNEL" = "Linux" ]; then
    ./configure --disable-zstd --disable-curl --disable-zlib --enable-gssapi --enable-sasl || error "Failed to configure and compile dependencies"
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


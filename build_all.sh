#!/usr/bin/env sh

error() {
  echo ERROR: "$1" >&2
  exit 1
}

if [ "$(uname -s)" != "Darwin" ]; then
  error "build_all is only supported on macOS"
fi

./build.sh || error "MacOS build failed"

docker build --platform linux/amd64 . -f Dockerfile -t librdkafka-builder:amd64 || error "Failed to create amd64 linux build container"
docker build --platform linux/arm64/v8 . -f Dockerfile -t librdkafka-builder:arm64 || error "Failed to create aarch64 linux build container"

docker run --rm -it --mount type=bind,source=./build.sh,destination=/build.sh --mount type=bind,source=./output,destination=/output librdkafka-builder:arm64 bash /build.sh || error "Linux aarch64 build failed"
docker run --rm -it --mount type=bind,source=./build.sh,destination=/build.sh --mount type=bind,source=./output,destination=/output librdkafka-builder:amd64 bash /build.sh || error "Linux amd64 build failed"

tar -czf arm64.tar.gz -C output/arm64 . || error "Failed to create macOS arm64 tarball"
tar -czf aarch64.tar.gz -C output/aarch64 . || error "Failed to create linux aarch64 tarball"
tar -czf x86_64.tar.gz -C output/x86_64 . || error "Failed to create linux amd64 tarball"

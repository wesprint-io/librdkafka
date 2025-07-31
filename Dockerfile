FROM debian:12
RUN apt-get update && apt-get install -y build-essential curl libsasl2-dev libzstd-dev python3 libssl-dev

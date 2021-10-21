ARG build_version="rust:1.51-slim-buster"
ARG build_type="source"
ARG openethereum_version=v3.2.6

# ******* Stage: builder ******* #
FROM ${build_version} as builder-source

ENV RUST_BACKTRACE 1

ARG openethereum_version

RUN apt update && apt install --yes --no-install-recommends \
  git \
  build-essential \
  cmake \
  libudev-dev

WORKDIR /tmp
RUN git clone  --depth 1 --branch ${openethereum_version} https://github.com/openethereum/openethereum
RUN cd openethereum && cargo build --release --features final --verbose
RUN cp -a /tmp/openethereum/target/release/. /tmp/bin

WORKDIR /tmp/openethereum

# ----- Stage: package install -----
FROM ubuntu:21.04 as builder-package

ARG openethereum_version

RUN apt update && apt install --yes --no-install-recommends curl ca-certificates unzip

RUN mkdir /tmp/bin && \
  curl -L https://github.com/openethereum/openethereum/releases/download/${openethereum_version}/openethereum-linux-${openethereum_version}.zip -o download.zip \
  && unzip download.zip -d /tmp/bin

RUN chmod 755 /tmp/bin/openethereum

FROM builder-${build_type} as build-condition

# ******* Stage: base ******* #
FROM ubuntu:21.04 as base

RUN apt update && apt install --yes --no-install-recommends \
    ca-certificates \
    cron \
    curl \
    pip \
    tini \
    zip unzip \
  # apt cleanup
	&& apt-get autoremove -y; \
	apt-get clean; \
	update-ca-certificates; \
	rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

WORKDIR /docker-entrypoint.d
COPY entrypoints /docker-entrypoint.d
COPY scripts/entrypoint.sh /usr/local/bin/openethereum-entrypoint

COPY scripts/openethereum-helper.py /usr/local/bin/openethereum-helper
RUN chmod 775 /usr/local/bin/openethereum-helper

RUN pip install click requests toml

ENTRYPOINT ["openethereum-entrypoint"]

# ******* Stage: testing ******* #
FROM base as test

ARG goss_version=v0.3.16

RUN curl -fsSL https://goss.rocks/install | GOSS_VER=${goss_version} GOSS_DST=/usr/local/bin sh

WORKDIR /test

COPY test /test
COPY --from=build-condition /tmp/bin/openethereum /usr/local/bin/

CMD ["goss", "--gossfile", "/test/goss.yaml", "validate"]

# ******* Stage: release ******* #
FROM base as release

ARG version=0.1.1

LABEL 01labs.image.authors="zer0ne.io.x@gmail.com" \
	01labs.image.vendor="O1 Labs" \
	01labs.image.title="0labs/openethereum" \
	01labs.image.description="Fast and feature-rich multi-network Ethereum client." \
	01labs.image.source="https://github.com/0x0I/container-file-openethereum/blob/${version}/Dockerfile" \
	01labs.image.documentation="https://github.com/0x0I/container-file-openethereum/blob/${version}/README.md" \
	01labs.image.version="${version}"

COPY --from=build-condition /tmp/bin/openethereum /usr/local/bin/

# exposing default ports
#
#     secret store
#     api    internal        rpc  ws   listener  discovery
#      ↓        ↓            ↓    ↓    ↓         ↓
EXPOSE 8082    8083          8545 8546 30303/tcp 30303/udp

CMD ["openethereum"]

# ******* Stage: tools ******* #

FROM ${build_version} as build-tools

ENV RUST_BACKTRACE 1

ARG openethereum_version

RUN apt update && apt install --yes --no-install-recommends \
  git \
  build-essential \
  cmake \
  libudev-dev

WORKDIR /tmp
RUN git clone  --depth 1 --branch ${openethereum_version} https://github.com/openethereum/openethereum

RUN cd /tmp/openethereum && cargo build -p ethkey-cli -p ethstore-cli --release

# ------- #

FROM base as tools

COPY --from=build-tools /tmp/openethereum/target/release/ethkey /tmp/openethereum/target/release/ethstore /usr/local/bin/
COPY --from=build-condition /tmp/bin/openethereum /usr/local/bin

CMD ["/bin/bash"]

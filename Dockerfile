ARG build_version="rust:1.51-slim-buster"

# ******* Stage: builder ******* #
FROM ${build_version} as builder

ENV RUST_BACKTRACE 1

ARG openethereum_version=v3.2.6

RUN apt update && apt install --yes --no-install-recommends \
  git \
  build-essential \
  cmake \
  libudev-dev

WORKDIR /tmp
RUN git clone https://github.com/openethereum/openethereum
RUN cd openethereum && git checkout ${openethereum_version} && cargo build --release --features final --verbose

WORKDIR /tmp/openethereum

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
COPY --from=builder /tmp/openethereum/target/release/openethereum /usr/local/bin/

CMD ["goss", "--gossfile", "/test/goss.yaml", "validate"]

# ******* Stage: release ******* #
FROM base as release

ARG version=0.2.0

LABEL 01labs.image.authors="zer0ne.io.x@gmail.com" \
	01labs.image.vendor="O1 Labs" \
	01labs.image.title="0labs/openethereum" \
	01labs.image.description="Fast and feature-rich multi-network Ethereum client." \
	01labs.image.source="https://github.com/0x0I/container-file-openethereum/blob/${version}/Dockerfile" \
	01labs.image.documentation="https://github.com/0x0I/container-file-openethereum/blob/${version}/README.md" \
	01labs.image.version="${version}"

COPY --from=builder /tmp/openethereum/target/release/openethereum /usr/local/bin/

EXPOSE 8545 8546 30303/tcp 30303/udp

CMD ["openethereum"]

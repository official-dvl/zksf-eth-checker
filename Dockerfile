# Independent check of OpenAI's "The Exponential Time Hypothesis is False" Lean proof (ZKSF, 27 Oct 2026).
# Every tool built from pinned source, as a non-root user, per the comparator README
# (https://github.com/leanprover/comparator). Build it with  docker build -t zksf-eth-check .
FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl ca-certificates build-essential pkg-config xz-utils zstd unzip python3 \
    && rm -rf /var/lib/apt/lists/*
# Go 1.24 (landrun's go.mod asks for 1.24.0), the official release tarball
RUN curl -sSfL https://go.dev/dl/go1.24.13.linux-amd64.tar.gz | tar -C /usr/local -xz
RUN useradd -m checker
USER checker
WORKDIR /home/checker
ENV PATH=/home/checker/bin:/home/checker/.elan/bin:/home/checker/.cargo/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN mkdir -p bin src
# Lean, the version openai/math pins in lean/lean-toolchain (leanprover/lean4:v4.34.1)
RUN curl -sSf https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh \
      | sh -s -- -y --default-toolchain leanprover/lean4:v4.34.1
# Rust, for nanoda (the independent second kernel)
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
# landrun from main's source, as the comparator README requires
RUN cd src && git clone https://github.com/Zouuup/landrun.git && cd landrun \
    && git checkout ec104f6edc1e && go build -o /home/checker/bin/landrun ./cmd/landrun
# elan defers the toolchain download; fetch it now so the image is complete and offline-ready
RUN elan toolchain install leanprover/lean4:v4.34.1 && elan default leanprover/lean4:v4.34.1 && lean --version
# lean4export and comparator at their v4.34.0 tags, built with Lean 4.34.1, because a tool that reads compiled .olean
# files must run on exactly the project's Lean version (openai/math pins v4.34.1).
RUN cd src && git clone https://github.com/leanprover/lean4export.git && cd lean4export && git checkout v4.34.0 \
    && echo "leanprover/lean4:v4.34.1" > lean-toolchain && lake build \
    && cp .lake/build/bin/lean4export /home/checker/bin/
RUN cd src && git clone https://github.com/leanprover/comparator.git && cd comparator && git checkout v4.34.0 \
    && echo "leanprover/lean4:v4.34.1" > lean-toolchain && lake build \
    && cp .lake/build/bin/comparator /home/checker/bin/
# nanoda, the independent second kernel (comparator's optional external check)
RUN cd src && git clone https://github.com/ammkrn/nanoda_lib.git && cd nanoda_lib && git checkout 37cb87b7e6cd \
    && cargo build --release && cp target/release/nanoda_bin /home/checker/bin/
# a wrapper so comparator's landrun runs in best-effort mode on kernels below Landlock ABI v10 (stated in the write-up)
RUN printf '#!/bin/sh\nexec /home/checker/bin/landrun --best-effort "$@"\n' > /home/checker/bin/landrun-best-effort \
    && chmod +x /home/checker/bin/landrun-best-effort

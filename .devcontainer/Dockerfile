FROM mcr.microsoft.com/devcontainers/base:ubuntu26.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG GPUTILS_URL="http://downloads.sourceforge.net/project/gputils/gputils/1.5.0/gputils-1.5.2.tar.bz2"
ARG GPSIM_URL="https://downloads.sourceforge.net/project/gpsim/gpsim/0.32.0/gpsim-0.32.1.tar.gz"

# Use the same source versions and environment as the CI toolchain.
ENV TOOL_PREFIX=/opt/otgw-toolchain
ENV PATH="${TOOL_PREFIX}/bin:${PATH}" \
    PKG_CONFIG_PATH="${TOOL_PREFIX}/lib/pkgconfig:${TOOL_PREFIX}/lib64/pkgconfig" \
    LD_LIBRARY_PATH="${TOOL_PREFIX}/lib:${TOOL_PREFIX}/lib64" \
    CPATH="${TOOL_PREFIX}/include" \
    LIBRARY_PATH="${TOOL_PREFIX}/lib:${TOOL_PREFIX}/lib64"

# VS Code probes login shells, which reset PATH via /etc/profile.
RUN printf 'export PATH="%s/bin:$PATH"\n' "${TOOL_PREFIX}" > /etc/profile.d/otgw-toolchain.sh

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        bison \
        build-essential \
        ca-certificates \
        curl \
        flex \
        libglib2.0-dev \
        libpopt-dev \
        libreadline-dev \
        libtool \
        pkg-config \
        subversion \
        tcl \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget -qO- "${GPUTILS_URL}" | tar xj \
    && cd gputils-1.5.2 \
    && ./configure --prefix="${TOOL_PREFIX}" \
    && make -j"$(nproc)" \
    && make install-exec install-data \
    && cd / \
    && rm -rf gputils-1.5.2

RUN wget -qO- "${GPSIM_URL}" | tar xz \
    && cd gpsim-0.32.1 \
    && ./configure --disable-gui --prefix="${TOOL_PREFIX}" \
    && make -j"$(nproc)" \
    && make install \
    && cd / \
    && rm -rf gpsim-0.32.1 \
    && ldconfig

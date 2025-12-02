FROM ghcr.io/nod-ai/ossci-gitops/iree-dev:main

LABEL org.opencontainers.image.source=https://github.com/krzysz00/amd-scripts
ARG LLVM_VERSION=21
ARG EMACS_VERSION=30.2

USER root
WORKDIR /
RUN usermod -m -d /home/kdrewnia -l kdrewnia ossci && \
    groupmod -n kdrewnia ossci && \
    sed -i -e 's/ossci/kdrewnia/' /etc/sudoers && \
    chsh -s /usr/bin/zsh kdrewnia

# Get manpages back
RUN yes | unminimize

# Last line is LLVM install script dependencies
RUN apt-get install -y tmux ncurses-term \
    direnv rcm python-is-python3 keychain \
    lsyncd rsync \
    man man-db zsh-doc \
    silversearcher-ag ripgrep \
    build-essential jq \
    lsb-release wget software-properties-common gnupg

RUN mkdir -p /opt/builds
WORKDIR /opt/builds

# Github CLI, adapted from their readme
RUN mkdir -p -m 755 /etc/apt/keyrings && mkdir -p -m 755 /etc/apt/sources.list.d
ADD --chmod=644 --checksum=sha256:20e0125d6f6e077a9ad46f03371bc26d90b04939fb95170f5a1905099cc6bcc0 https://cli.github.com/packages/githubcli-archive-keyring.gpg /etc/apt/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" >/etc/apt/sources.list.d/github-cli.list && \
    sudo apt-get update -y && \
    sudo apt-get install -y gh

# LLVM

ADD --chmod=755 https://apt.llvm.org/llvm.sh /opt/builds/llvm-install.sh
RUN /opt/builds/llvm-install.sh ${LLVM_VERSION} all
COPY update-alternatives-clang /opt/builds
RUN ./update-alternatives-clang

# Emacs
RUN apt-get -y install libgnutls28-dev libtree-sitter0 libtree-sitter-dev libgccjit-14-dev libsystemd-dev libgpm-dev gcc-14
ADD https://ftpmirror.gnu.org/emacs/emacs-${EMACS_VERSION}.tar.xz /opt/builds
RUN tar xf emacs-${EMACS_VERSION}.tar.xz
WORKDIR /opt/builds/emacs-${EMACS_VERSION}
RUN env CC=gcc-14 CFLAGS="-g3 -O3 -mtune=native" ./configure --with-libsystemd --without-gconf --with-native-compilation --with-x=no --without-gsettings --with-tree-sitter && \
    make -j8 && \
    make install
WORKDIR /opt/builds

# Set up lsyncd config
COPY lsyncd.conf /etc/lsyncd.conf

USER kdrewnia
WORKDIR /home/kdrewnia

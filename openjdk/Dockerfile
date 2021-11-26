FROM ubuntu:20.04

WORKDIR /root/

COPY qemu-5.2.0.tar.xz ./
COPY riscv-gnu-toolchain.tbz ./

# RUN sed -i 's,archive.ubuntu.com,mirrors.tuna.tsinghua.edu.cn,g' /etc/apt/sources.list
RUN apt-get update -qq \
	&& \
	DEBIAN_FRONTEND=noninteractive \
	apt install -y -qq --no-install-recommends \
	vim htop tmux git build-essential cmake wget expect  python3 python3-pip ninja-build cmake pkg-config libglib2.0-dev libpixman-1-dev \
	autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev \
	gawk build-essential bison flex texinfo gperf libtool patchutils bc \
	zlib1g-dev libexpat-dev git \
	libglib2.0-dev libfdt-dev libpixman-1-dev \
	libncurses5-dev libncursesw5-dev ninja-build \
	python3 autopoint pkg-config zip unzip screen \
	make libxext-dev libxrender-dev libxtst-dev \
	libxt-dev libcups2-dev libfreetype6-dev \
	mercurial libasound2-dev cmake libfontconfig1-dev python3-pip \
	gettext \
	libffi-dev \
	libltdl-dev \
	&& \
	rm -rf /var/lib/apt/lists/*

COPY docker_bootstrap.sh ./
RUN bash docker_bootstrap.sh

COPY manual_install_deps.sh ./
RUN bash manual_install_deps.sh

COPY build_ext_libs_32.sh ./
RUN bash build_ext_libs_32.sh

COPY build_jdk.sh ./
RUN bash build_jdk.sh

COPY run_jdk.sh ./
RUN bash run_jdk.sh

CMD bash


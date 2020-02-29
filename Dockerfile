FROM debian:buster AS build

ARG OE_RELEASE=2019-10.2-zeus

MAINTAINER Michael Weiser <michael.weiser@gmx.de>

RUN apt-get update -qq -y
RUN apt-get dist-upgrade -y
RUN apt-get autoremove -y
RUN apt-get install -y gawk wget git-core diffstat unzip texinfo \
	build-essential chrpath socat cpio python python3 python3-pip \
	python3-pexpect xz-utils debianutils iputils-ping locales

# bitbake needs locale set up
RUN echo en_US UTF-8 > /etc/locale.gen
RUN locale-gen

# bitbake does not want to be run as root
RUN useradd -m bitbake
USER bitbake
WORKDIR /home/bitbake

ARG OE_BASENAME=openembedded-core-${OE_RELEASE}
ARG OE_ARCHIVE=${OE_BASENAME}.tar.bz2
ARG OE_ROOT=/home/bitbake/${OE_BASENAME}

# plain HTTP to allow caching, verification necessary anyway
RUN wget http://git.openembedded.org/openembedded-core/snapshot/${OE_ARCHIVE}
RUN sha256sum ${OE_ARCHIVE} | \
	grep '^8b9728c8fe69fef7b23396565069fea89a00e733765bcdfe33a6c91c59f003f0 ' >/dev/null
RUN tar -xf ${OE_ARCHIVE}

WORKDIR ${OE_ROOT}

ARG BB_BASENAME=bitbake-${OE_RELEASE}
ARG BB_ARCHIVE=${BB_BASENAME}.tar.bz2
ARG BB_ROOT=/home/bitbake/${BB_BASENAME}

RUN wget http://git.openembedded.org/bitbake/snapshot/${BB_ARCHIVE}
RUN sha256sum ${BB_ARCHIVE} | \
	grep '^fb371b6d13a4e46310eafd37db5bca58ab788e840a56868c9f0a1d930e75068a ' >/dev/null
RUN tar -xf ${BB_ARCHIVE}

ENV BBEXTRA=-${OE_RELEASE}
RUN mkdir -p build/conf
RUN echo 'MACHINE ??= "root-armv5b"' > build/conf/local.conf
run ( echo 'DEFAULTTUNE ?= "armv5b"' ; \
	echo 'require conf/machine/include/arm/arch-armv5.inc' ) > meta/conf/machine/root-armv5b.conf
run ( echo 'IMAGE_INSTALL ?= "autoconf bash binutils gcc make"' ; \
	echo 'IMAGE_FEATURES += "dev-pkgs"' ; \
	echo 'inherit core-image' ) > meta/recipes-core/images/root-armv5b-dev.bb
RUN bash -c '. oe-init-build-env && \
	bitbake root-armv5b-dev'

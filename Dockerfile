# This file describes how to build reprepro within a container.
#
FROM ubuntu:trusty
MAINTAINER Zenoss, Inc <dev@zenoss.com>	

# Re-sync local debian package index files from their sources
# so the newest versions of availabile packages and their 
# dependencies are used.
#
RUN	apt-get update -q

# Build tools
#
RUN	DEBIAN_FRONTEND=noninteractive apt-get install -y -q autoconf git make shtool wget dpkg-sig
#
# Build dependencies
#
# NB:  Squelch 'debconf: unable to initialize frontend: Dialog' 
#      chatter we get with some deb prereqs.
#      See: https://github.com/phusion/baseimage-docker/issues/58
#
RUN	DEBIAN_FRONTEND=noninteractive apt-get install -y -q libbz2-dev libdb-dev libgpgme11-dev liblzma-dev zlib1g-dev

ENV     BLDDIR   /tmp/build
ENV     SRCDIR   /tmp/build/reprepro
ENV     PATCHDIR /tmp/build/patches
ENV     INSTDIR  /usr/local/bin

RUN	mkdir -p ${BLDDIR} ${SRCDIR} ${PATCHDIR} ${INSTDIR}
RUN	git clone http://anonscm.debian.org/cgit/mirrorer/reprepro.git ${SRCDIR}
#
# Checkout upstream source on commit boundary proximate to 
# community patch.  (Version: 4.14.0+)
#
# See:
#
# http://anonscm.debian.org/cgit/mirrorer/reprepro.git/commit/?id=5b0f216db6aca2b4a5e7fb10f18c23d8d439d3b6
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=570623
#
RUN     cd ${SRCDIR} && git checkout 5b0f216db6aca2b4a5e7fb10f18c23d8d439d3b6
ADD	0001-Fix-indentation-spaces-to-tabs.patch ${PATCHDIR}/
ADD	Add-multiple-version-management.patch     ${PATCHDIR}/

RUN	cd ${SRCDIR} && patch --dry-run -p1 < ${PATCHDIR}/0001-Fix-indentation-spaces-to-tabs.patch
RUN	cd ${SRCDIR} && patch -p1 < ${PATCHDIR}/0001-Fix-indentation-spaces-to-tabs.patch
RUN	cd ${SRCDIR} && patch --dry-run -p1 < ${PATCHDIR}/Add-multiple-version-management.patch
RUN	cd ${SRCDIR} && patch -p1 < ${PATCHDIR}/Add-multiple-version-management.patch
RUN	cd ${SRCDIR} && ./autogen.sh
RUN	cd ${SRCDIR} && ./configure
RUN	cd ${SRCDIR} && make
RUN	cd ${SRCDIR} && make install

RUN     apt-get install -y -q ruby ruby-dev
RUN     gem install fpm

RUN     mkdir /tmp/pkgroot/usr/local/bin -p && \
        cp /usr/local/bin/reprepro /tmp/pkgroot/usr/local/bin/zreprepro

RUN     cd tmp/ && \
        fpm -n zreprepro \
        -s dir \
        -C pkgroot/ \
        -v 1.0 \
        -t deb \
        .

#!/bin/bash

set -e
set -u


url="$1"
tarball=$(basename "$url")

eval $(echo "$tarball" | sed -r 's!^(.+)-([^-]+)\.tar\.(\w+)$!name=\1\nver=\2\ncomp=\3\n!')

name_lc=${name,,}

mkdir -p $name_lc
cd $name_lc
wget -O $tarball -c "$url"

cat <<Makefile > Makefile
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
# Copyright (c) 2011, Nexenta Systems, Inc. and/or its affiliates. All rights reserved.
#

include ../../../make-rules/shared-macros.mk
COMPONENT_NAME=     $name
COMPONENT_VERSION=  $ver
COMPONENT_SRC=      \$(COMPONENT_NAME)-\$(COMPONENT_VERSION)
COMPONENT_ARCHIVE=  \$(COMPONENT_SRC).tar.$comp
COMPONENT_ARCHIVE_HASH= sha1:$(sha1sum $tarball | cut -d ' ' -f 1)
COMPONENT_ARCHIVE_URL=  $(dirname $url)/\$(COMPONENT_ARCHIVE)

include \$(WS_TOP)/make-rules/prep.mk
include \$(WS_TOP)/make-rules/ips.mk
include \$(WS_TOP)/make-rules/makemaker.mk

COMPILER = gcc
CONFIGURE_OPTIONS<----->+=CC=gcc

build:      \$(BUILD_32)

install:    \$(INSTALL_32)

COMPONENT_TEST_TARGETS = test
test:       \$(TEST_32)

BUILD_PKG_DEPENDENCIES =        \$(BUILD_TOOLS)

include \$(WS_TOP)/make-rules/depend.mk

Makefile

make install

if tar xf "$tarball" "$name-$ver/META.yml" --strip-components=1; then
    summary=$(grep abstract: META.yml | sed 's,abstract: *,,')
    rm META.yml
else
    summary=''
fi

cat <<Manifest > $name_lc.p5m
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
# or http://www.opensolaris.org/os/licensing.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at usr/src/OPENSOLARIS.LICENSE.
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
# Copyright (c) 2011, Nexenta Systems, Inc. and/or its affiliates. All rights reserved.
#

<transform file path=usr.*/man/.+ -> default mangler.man.stability uncommitted>
set name=pkg.fmri value=pkg:/library/perl-5/$name_lc@\$(IPS_COMPONENT_VERSION),\$(BUILD_VERSION)
set name=info.classification value="org.opensolaris.category.2008:Development/Perl"
set name=pkg.summary value="$summary"

$(../../../tools/make-payload.sh build/proto/i386 | grep -v 'perllocal\.pod' | grep -v '\.packlist')

depend fmri=runtime-perl-510 type=require
#depend fmri=library/perl-5/ type=require

Manifest


exit 0


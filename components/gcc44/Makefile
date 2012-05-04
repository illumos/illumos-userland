#
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
# Copyright (c) 2012 Nexenta Systems, Inc.  All rights reserved.
# Copyright (c) 2011, OpenIndiana project. All rights reserved.
#
include ../../make-rules/shared-macros.mk

COMPONENT_NAME=		gcc
COMPONENT_VERSION=	4.4.4
COMPONENT_SRC=		$(COMPONENT_NAME)-$(COMPONENT_VERSION)
COMPONENT_ARCHIVE=	$(COMPONENT_SRC).tar.bz2
COMPONENT_ARCHIVE_HASH=	sha1:45d1e7242a08cbb7a343ed2bf640a5afd0ebe098
COMPONENT_ARCHIVE_URL=	http://ftp.gnu.org/gnu/gcc/$(COMPONENT_NAME)-$(COMPONENT_VERSION)/$(COMPONENT_ARCHIVE)
COMPONENT_PROJECT_URL=  http://gcc.gnu.org/

include ../../make-rules/prep.mk
include ../../make-rules/configure.mk
include ../../make-rules/ips.mk

GCC_ROOT=/usr/gcc/4.4
COMPILER=gcc

CPPFLAGS+= -fexceptions

CONFIGURE_PREFIX    =           /usr/gcc/4.4
CONFIGURE_OPTIONS  +=           CPPFLAGS="$(CPPFLAGS)"
CONFIGURE_OPTIONS  +=           --with-gmp=$(CONFIGURE_PREFIX)
CONFIGURE_OPTIONS  +=           --with-mpfr=$(CONFIGURE_PREFIX)
CONFIGURE_OPTIONS  +=           --with-mpc=$(CONFIGURE_PREFIX)
CONFIGURE_OPTIONS  +=           --without-ppl
CONFIGURE_OPTIONS  +=           --without-cloog
CONFIGURE_OPTIONS  +=           --with-gnu-as
CONFIGURE_OPTIONS  +=		--with-as=$(SFWBIN)/gas
CONFIGURE_OPTIONS  +=           --with-ld=/usr/ccs/bin/ld
CONFIGURE_OPTIONS  +=           --enable-stage1-languages=c
CONFIGURE_OPTIONS  +=           --enable-languages=c,c++,objc,fortran
CONFIGURE_OPTIONS  +=           --with-stage1-ldflags="-R$(CONFIGURE_PREFIX)/lib"
CONFIGURE_OPTIONS  +=           --with-boot-ldflags="-R$(CONFIGURE_PREFIX)/lib"

include ../../make-rules/shared-targets.mk

build:		$(BUILD_32)

install:	$(INSTALL_32)

BUILD_PKG_DEPENDENCIES =	$(BUILD_TOOLS)

include ../../make-rules/depend.mk

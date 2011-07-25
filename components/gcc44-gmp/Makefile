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
# Copyright (c) 2011, OpenIndiana project. All rights reserved.
#
include ../../make-rules/shared-macros.mk

COMPONENT_NAME=		gmp
COMPONENT_VERSION=	4.3.2
COMPONENT_SRC=		$(COMPONENT_NAME)-$(COMPONENT_VERSION)
COMPONENT_ARCHIVE=	$(COMPONENT_SRC).tar.bz2
COMPONENT_ARCHIVE_HASH=	sha1:c011e8feaf1bb89158bd55eaabd7ef8fdd101a2c
COMPONENT_ARCHIVE_URL=	ftp://ftp.gmplib.org/pub/$(COMPONENT_NAME)-$(COMPONENT_VERSION)/$(COMPONENT_ARCHIVE)
COMPONENT_PROJECT_URL=  http://gmplib.org/

include ../../make-rules/prep.mk
include ../../make-rules/configure.mk
include ../../make-rules/ips.mk

GCC_ROOT=/usr/gcc/4.4
COMPILER=gcc

CPPFLAGS+= -fexceptions

CONFIGURE_PREFIX    =           /usr/gcc/4.4
CONFIGURE_OPTIONS  +=           CPPFLAGS="$(CPPFLAGS)"
CONFIGURE_OPTIONS  +=           ABI=32
CONFIGURE_OPTIONS  +=           --enable-cxx
CONFIGURE_OPTIONS  +=           --disable-static

include ../../make-rules/shared-targets.mk

build:		$(BUILD_32)

install:	$(INSTALL_32)

BUILD_PKG_DEPENDENCIES =	$(BUILD_TOOLS)

include ../../make-rules/depend.mk

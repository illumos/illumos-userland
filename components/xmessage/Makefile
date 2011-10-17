#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL)". You may
# only use this file in accordance with the terms of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source. A copy of the CDDL is also available via the Internet at
# http://www.illumos.org/license/CDDL.
#

#
# Copyright 2011 Josef 'Jeff' Sipek <jeffpc@josefsipek.net>
#
include ../../make-rules/shared-macros.mk

COMPONENT_NAME=		xmessage
COMPONENT_VERSION=	1.0.3
COMPONENT_SRC=		$(COMPONENT_NAME)-$(COMPONENT_VERSION)
COMPONENT_ARCHIVE=	$(COMPONENT_SRC).tar.bz2
COMPONENT_ARCHIVE_HASH=	sha1:a8bfefbbe7785fa0e58ed4f596f4d79ba0b4d9b2
COMPONENT_ARCHIVE_URL=	http://xorg.freedesktop.org/archive/individual/app/$(COMPONENT_ARCHIVE)
COMPONENT_PROJECT_URL=	http://xorg.freedesktop.org

include ../../make-rules/prep.mk
include ../../make-rules/configure.mk
include ../../make-rules/ips.mk

build:		$(BUILD_32)

install:	$(INSTALL_32)

test:		$(TEST_32)

BUILD_PKG_DEPENDENCIES =	$(BUILD_TOOLS)

include ../../make-rules/depend.mk

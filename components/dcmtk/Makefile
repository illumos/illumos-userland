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
# Copyright 2011 Paolo Marcheschi paolo.marcheschi@gmail.com
# with the invaluable help of Josef 'Jeff' Sipek <jeffpc@josefsipek.net>
#
include ../../make-rules/shared-macros.mk

COMPONENT_NAME=		dcmtk
COMPONENT_VERSION=	3.6.0
COMPONENT_SRC=		$(COMPONENT_NAME)-$(COMPONENT_VERSION)
COMPONENT_ARCHIVE=	$(COMPONENT_SRC).zip
COMPONENT_ARCHIVE_HASH=	sha1:e3cab3cadbdb68c92939439cf14425b06a334204
COMPONENT_ARCHIVE_URL=	http://dicom.offis.de/download/dcmtk/dcmtk360/$(COMPONENT_ARCHIVE)
COMPONENT_PROJECT_URL=	http://dicom.offis.de/dcmtk

include ../../make-rules/prep.mk
include ../../make-rules/configure.mk
include ../../make-rules/ips.mk

COMPILER=gcc

COMPONENT_PRE_CONFIGURE_ACTION = \
	($(CLONEY) $(SOURCE_DIR) $(@D))

CONFIGURE_OPTIONS       += --sysconfdir=/etc
CONFIGURE_OPTIONS       += --with-private-tags
CONFIGURE_OPTIONS       += --datarootdir=/usr/share
CONFIGURE_OPTIONS       += --datadir=/usr/share/dcmtk
CONFIGURE_OPTIONS       += --docdir=$(CONFIGURE_PREFIX)/share/doc/dcmtk


build:		$(BUILD_32)

install:	$(INSTALL_32)

test:		$(TEST_32)

BUILD_PKG_DEPENDENCIES =	$(BUILD_TOOLS)

include ../../make-rules/depend.mk

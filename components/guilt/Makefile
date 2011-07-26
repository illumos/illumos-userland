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
# Copyright 2011 Josef 'Jeff' Sipek <jeffpc@josefsipek.net>
#
include ../../make-rules/shared-macros.mk

COMPONENT_NAME=		guilt
COMPONENT_VERSION=	0.35
COMPONENT_SRC=		$(COMPONENT_NAME)-$(COMPONENT_VERSION)
COMPONENT_ARCHIVE=	$(COMPONENT_SRC).tar.bz2
COMPONENT_ARCHIVE_HASH=	sha1:054667522de9083ca8e93a3fae232de65e235813
COMPONENT_ARCHIVE_URL=	http://www.kernel.org/pub/linux/kernel/people/jsipek/guilt/$(COMPONENT_ARCHIVE)

include ../../make-rules/prep.mk
include ../../make-rules/justmake.mk
include ../../make-rules/ips.mk

COMPONENT_INSTALL_TARGETS = install install-doc

COMPONENT_INSTALL_ENV += INSTALL=$(INSTALL)
COMPONENT_INSTALL_ENV += PREFIX=/usr
COMPONENT_INSTALL_ENV += mandir=/usr/share/man

build:		$(BUILD_32)

install:	$(INSTALL_32)

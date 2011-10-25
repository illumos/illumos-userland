include ../../../make-rules/shared-macros.mk
COMPONENT_NAME     =  Babel
COMPONENT_VERSION  =  0.9.6
COMPONENT_SRC      =  $(COMPONENT_NAME)-$(COMPONENT_VERSION)
COMPONENT_ARCHIVE  =  $(COMPONENT_SRC).zip
COMPONENT_ARCHIVE_HASH = sha1:6823ed1013c8ad3513d58248c3e9cdc11d232e38
COMPONENT_ARCHIVE_URL  = http://pypi.python.org/packages/source/B/Babel/$(COMPONENT_ARCHIVE)

include $(WS_TOP)/make-rules/prep.mk
include $(WS_TOP)/make-rules/ips.mk
include $(WS_TOP)/make-rules/setup.py.mk

build:      $(BUILD_32)
install:    $(INSTALL_32)

COMPONENT_TEST_TARGETS = test
test:       $(TEST_32)

BUILD_PKG_DEPENDENCIES = $(BUILD_TOOLS)

include $(WS_TOP)/make-rules/depend.mk


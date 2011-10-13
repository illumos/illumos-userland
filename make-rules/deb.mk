
# shared-macros.mk and ips.mk must be included before

DEBMAKER = $(WS_TOOLS)/debmaker.pl
DEBVERSION ?= $(BUILD_NUM).0

# Where to find binaries
# (like debian/tmp):
PROTO_DIRS = $(PKG_PROTO_DIRS:%=-d %)

# Where to create package contents
# and debs (like debian/pkg-name)
DEBS_DIR = $(PROTO_DIR)/debs

# Actually we need $(RESOLVED),
# but pkgdepend resolve does not work:
deb: build install $(DEPENDED)
	rm -rf $(DEBS_DIR)
	$(MKDIR) $(DEBS_DIR)
	$(DEBMAKER) \
		-S $(COMPONENT_NAME) \
		-N $(CONSOLIDATION) \
		-V $(DEBVERSION) \
		-D $(DEBS_DIR) \
		$(PROTO_DIRS) $(DEPENDED)



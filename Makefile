SOURCES = $(shell pwd)/sources

-include versions.mak
-include source_urls.mak

DL_CMD = curl -L4 --connect-timeout 5 --retry 5 --retry-delay 5 --retry-max-time 25 -o
SHA1_CMD = sha1sum -c

COWPATCH = $(CURDIR)/cowpatch.sh

HOST = $(if $(NATIVE),$(TARGET))
BUILD_DIR = build/$(if $(HOST),$(HOST),local)/$(TARGET)
OUTPUT = $(CURDIR)/output$(if $(HOST),-$(HOST))

REL_TOP = ../../..

SRC_DIRS = gcc-$(GCC_VER) binutils-$(BINUTILS_VER) musl-$(MUSL_VER) \
	$(if $(GMP_VER),gmp-$(GMP_VER)) \
	$(if $(MPC_VER),mpc-$(MPC_VER)) \
	$(if $(MPFR_VER),mpfr-$(MPFR_VER)) \
	$(if $(ISL_VER),isl-$(ISL_VER)) \
	$(if $(LINUX_VER),linux-$(LINUX_VER))

all:

clean:
	rm -rf gcc-* binutils-* musl-* gmp-* mpc-* mpfr-* isl-* build build-* linux-*

distclean: clean
	rm -rf sources


# Rules for downloading and verifying sources. Treat an external SOURCES path as
# immutable and do not try to download anything into it.

ifeq ($(SOURCES),$(shell pwd)/sources)

$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/gmp*)): SITE = $(GMP_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/mpc*)): SITE = $(MPC_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/mpfr*)): SITE = $(MPFR_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/isl*)): SITE = $(ISL_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/binutils-*.*.tar*)): SITE = $(BINUTILS_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/binutils-*.*.*.tar*)): SITE = $(BINUTILS_SNAP)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/gcc-*)): SITE = $(GCC_SITE)/$(basename $(basename $(notdir $@)))
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/gcc-*-*)): SITE = $(GCC_SNAP)/$(subst gcc-,,$(basename $(basename $(notdir $@))))
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/musl-1.*)): SITE = $(MUSL_RELEASE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/musl-[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]*)): SITE = $(MUSL_SNAPSHOT)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-7*)): SITE = $(LINUX_SITE)/v7.x
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-6*)): SITE = $(LINUX_SITE)/v6.x
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-5*)): SITE = $(LINUX_SITE)/v5.x
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-4*)): SITE = $(LINUX_SITE)/v4.x
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-3*)): SITE = $(LINUX_SITE)/v3.x
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-2.6*)): SITE = $(LINUX_SITE)/v2.6
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-headers-*)): SITE = $(LINUX_HEADERS_SITE)

$(SOURCES):
	mkdir -p $@

$(SOURCES)/config.sub: | $(SOURCES)
	mkdir -p $@.tmp
	cd $@.tmp && $(DL_CMD) $(notdir $@) "https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=$(CONFIG_SUB_REV)"
	cd $@.tmp && touch $(notdir $@)
	cd $@.tmp && $(SHA1_CMD) $(CURDIR)/hashes/$(notdir $@).$(CONFIG_SUB_REV).sha1
	mv $@.tmp/$(notdir $@) $@
	rm -rf $@.tmp

$(SOURCES)/%: hashes/%.sha1 | $(SOURCES)
	mkdir -p $@.tmp
	cd $@.tmp && $(DL_CMD) $(notdir $@) $(SITE)/$(notdir $@)
	cd $@.tmp && touch $(notdir $@)
	cd $@.tmp && $(SHA1_CMD) $(CURDIR)/hashes/$(notdir $@).sha1
	mv $@.tmp/$(notdir $@) $@
	rm -rf $@.tmp

endif


# Rules for extracting and patching sources, or checking them out from git.

musl-git-%:
	rm -rf $@.tmp
	git clone --shallow-submodules --recurse-submodules --depth 1 -b $(patsubst musl-git-%,%,$@) $(MUSL_REPO) $@.tmp
	cd $@.tmp && git fsck
	mv $@.tmp $@

%.orig: $(SOURCES)/%.tar.gz
	case "$@" in */*) exit 1 ;; esac
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar zxvf - ) < $<
	rm -rf $@
	touch $@.tmp/$(patsubst %.orig,%,$@)
	mv $@.tmp/$(patsubst %.orig,%,$@) $@
	rm -rf $@.tmp
	case "$@" in binutils-*) rm -f $@/gas/doc/.dirstamp ;; esac

%.orig: $(SOURCES)/%.tar.bz2
	case "$@" in */*) exit 1 ;; esac
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar jxvf - ) < $<
	rm -rf $@
	touch $@.tmp/$(patsubst %.orig,%,$@)
	mv $@.tmp/$(patsubst %.orig,%,$@) $@
	rm -rf $@.tmp
	case "$@" in binutils-*) rm -f $@/gas/doc/.dirstamp ;; esac

%.orig: $(SOURCES)/%.tar.xz
	case "$@" in */*) exit 1 ;; esac
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar Jxvf - ) < $<
	rm -rf $@
	touch $@.tmp/$(patsubst %.orig,%,$@)
	mv $@.tmp/$(patsubst %.orig,%,$@) $@
	rm -rf $@.tmp
	case "$@" in binutils-*) rm -f $@/gas/doc/.dirstamp ;; esac

%: %.orig | $(SOURCES)/config.sub
	case "$@" in */*) exit 1 ;; esac
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && $(COWPATCH) -I ../$< )
	test ! -d patches/$@ || cat patches/$@/* | ( cd $@.tmp && $(COWPATCH) -p1 )
	if test -f $</configfsf.sub ; then cs=configfsf.sub ; elif test -f $</config.sub ; then cs=config.sub ; else exit 0 ; fi ; rm -f $@.tmp/$$cs && cp -f $(SOURCES)/config.sub $@.tmp/$$cs && chmod +x $@.tmp/$$cs
	rm -rf $@
	mv $@.tmp $@


# Add deps for all patched source dirs on their patchsets
$(foreach dir,$(notdir $(basename $(basename $(basename $(wildcard hashes/*))))),$(eval $(dir): $$(wildcard patches/$(dir) patches/$(dir)/*)))

extract_all: | $(SRC_DIRS)


# Rules for building.

ifeq ($(TARGET),)

all:
	@echo TARGET must be set via config.mak or command line.
	@exit 1

else

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/Makefile: | $(BUILD_DIR)
	ln -sf $(REL_TOP)/litecross/Makefile $@

$(BUILD_DIR)/config.mak: | $(BUILD_DIR)
	printf >$@ '%s\n' \
	"TARGET = $(TARGET)" \
	"HOST = $(HOST)" \
	"MUSL_SRCDIR = $(REL_TOP)/musl-$(MUSL_VER)" \
	"GCC_SRCDIR = $(REL_TOP)/gcc-$(GCC_VER)" \
	"BINUTILS_SRCDIR = $(REL_TOP)/binutils-$(BINUTILS_VER)" \
	$(if $(GMP_VER),"GMP_SRCDIR = $(REL_TOP)/gmp-$(GMP_VER)") \
	$(if $(MPC_VER),"MPC_SRCDIR = $(REL_TOP)/mpc-$(MPC_VER)") \
	$(if $(MPFR_VER),"MPFR_SRCDIR = $(REL_TOP)/mpfr-$(MPFR_VER)") \
	$(if $(ISL_VER),"ISL_SRCDIR = $(REL_TOP)/isl-$(ISL_VER)") \
	$(if $(LINUX_VER),"LINUX_SRCDIR = $(REL_TOP)/linux-$(LINUX_VER)") \
	"-include $(REL_TOP)/config.mak"

all: | $(SRC_DIRS) $(BUILD_DIR) $(BUILD_DIR)/Makefile $(BUILD_DIR)/config.mak
	cd $(BUILD_DIR) && $(MAKE) $@

install: | $(SRC_DIRS) $(BUILD_DIR) $(BUILD_DIR)/Makefile $(BUILD_DIR)/config.mak
	cd $(BUILD_DIR) && $(MAKE) OUTPUT=$(OUTPUT) $@

endif

.SECONDARY:

download_only: $(foreach dir,$(SRC_DIRS),$(patsubst hashes/$(dir).%.sha1,$(SOURCES)/$(dir).%,$(wildcard hashes/$(dir).*)))
	@echo "All sources downloaded."

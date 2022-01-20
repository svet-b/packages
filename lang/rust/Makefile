# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
include $(TOPDIR)/rules.mk

PKG_NAME:=rust
PKG_VERSION:=1.58.0
PKG_RELEASE:=1

PKG_LICENSE:=Apache-2.0 MIT
PKG_LICENSE_FILES:=LICENSE-APACHE LICENSE-MIT

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/rust-lang/rust.git
PKG_SOURCE_DATE:=2022-01-11
PKG_SOURCE_VERSION:=02072b482a8b5357f7fb5e5637444ae30e423c40
PKG_MIRROR_HASH:=skip
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/cmake.mk
include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/package.mk

# Currently, only HOST toolchain for cross-compile use is working
PKG_HOST_ONLY:=1
CMAKE_INSTALL:=1

# Requires Python3 to build
HOST_BUILD_DEPENDS:=python3/host

# Rust Environmental Vars
CONFIG_HOST_SUFFIX:=$(shell cut -d"-" -f4 <<<"$(GNU_HOST_NAME)")
RUSTC_HOST_ARCH:=$(HOST_ARCH)-unknown-linux-$(CONFIG_HOST_SUFFIX)
RUSTC_TARGET_ARCH:=$(REAL_GNU_TARGET_NAME)
CARGO_HOME:=$(STAGING_DIR_HOST)/.cargo

# Commit hash for LLVM binary from CI
# Obtained by running
# git rev-list --author=bors@rust-lang.org -n1 --first-parent HEAD -- src/llvm-project src/bootstrap/download-ci-llvm-stamp src/version
# from top level of checked out git repo
LLVM_GIT_SHA:=faea820643f9acec1bb787941063393f9508a775

# Rust Temp Directory
RUST_TMP_DIR:=$(TMP_DIR)/rust-install

RUST_INSTALL_HOST_FILENAME:=$(PKG_NAME)-$(PKG_VERSION)-$(RUSTC_HOST_ARCH)-install.tar.xz
RUST_INSTALL_TARGET_FILENAME:=$(PKG_NAME)-$(PKG_VERSION)-$(RUSTC_TARGET_ARCH)-install.tar.xz

# Rust-lang has an uninstall script
RUST_UNINSTALL:=$(STAGING_DIR_HOST)/lib/rustlib/uninstall.sh

# This checks to see if the dist installation already exists
IS_RUSTC_INSTALLED:=$(or $(and $(wildcard $(STAGING_DIR_HOST)/bin/rustc),true),false)
IS_CARGO_INSTALLED:=$(or $(and $(wildcard $(STAGING_DIR_HOST)/bin/cargo),true),false)

# MUSL Target Flags
MUSL_CONFIGURE_ARGS = \
  --set=target.$(RUSTC_TARGET_ARCH).ar=$(TARGET_AR) \
  --set=target.$(RUSTC_TARGET_ARCH).cc=$(TARGET_CC_NOCACHE) \
  --set=target.$(RUSTC_TARGET_ARCH).cxx=$(TARGET_CXX_NOCACHE) \
  --set=target.$(RUSTC_TARGET_ARCH).linker=$(TARGET_CC_NOCACHE) \
  --set=target.$(RUSTC_TARGET_ARCH).musl-root=$(TOOLCHAIN_DIR) \
  --set=target.$(RUSTC_TARGET_ARCH).ranlib=$(TARGET_RANLIB)

# CARGO_HOME is an environmental
#TARGET_CONFIGURE_OPTS += CARGO_HOME=$(CARGO_HOME)
HOST_CONFIGURE_OPTS += CARGO_HOME=$(CARGO_HOME)

# The Flags are Common between HOST and TARGET
RUST_COMMOM_ARGS := \
  --build=$(RUSTC_HOST_ARCH) \
  --dist-compression-formats=xz \
  --enable-full-tools \
  --tools=cargo \
  --disable-docs \
  --enable-vendor \
  --set=llvm.download-ci-llvm="if-available" \
  --enable-missing-tools \
  --release-channel=nightly \
  ${MUSL_CONFIGURE_ARGS}

##
# Because OpenWrt uses default configure flags that are not recognized
# we override the default and set our own.
#
# Rust HOST Configuration Arguments
HOST_CONFIGURE_ARGS = \
  --target=$(RUSTC_TARGET_ARCH) \
  --host=$(RUSTC_HOST_ARCH) \
  --prefix=$(STAGING_DIR_HOST) \
  --bindir=$(STAGING_DIR_HOST)/bin \
  --libdir=$(STAGING_DIR_HOST)/lib \
  --sysconfdir=$(STAGING_DIR_HOST)/etc \
  --datadir=$(STAGING_DIR_HOST)/share \
  --mandir=$(STAGING_DIR_HOST)/man \
  ${RUST_COMMOM_ARGS}

# Rust TARGET Configuration Args
#CONFIGURE_ARGS = \
#  --target=$(RUSTC_TARGET_ARCH) \
#  --host=$(RUSTC_TARGET_ARCH) \
#  --prefix=$(CONFIGURE_PREFIX) \
#  --bindir=$(CONFIGURE_PREFIX)/bin \
#  --libdir=$(CONFIGURE_PREFIX)/lib \
#  --sysconfdir=$(CONFIGURE_PREFIX)/etc \
#  --datadir=$(CONFIGURE_PREFIX)/share \
#  --mandir=$(CONFIGURE_PREFIX)/man \
#  $(RUST_COMMOM_ARGS) \
#  --set=llvm.cxxflags='$(RUST_LLVM_CXXFLAGS)'

# Add rust_config.mk Debug flags
#include ./rust_config.mk

define Host/Prepare
	# Allows outside packages to call $$$$(BUILD_DIR_HOST)/rust as the dir
	# rather than needing the version number.
	[ -L $(BUILD_DIR_HOST)/rust ] || \
	  (cd $(BUILD_DIR_HOST); ln -s "$(PKG_NAME)-$(PKG_VERSION)" rust)

	[ -d $(RUST_TMP_DIR) ] || \
	  mkdir -p $(RUST_TMP_DIR)

	$(call Host/Prepare/Default)
endef

define Host/Uninstall
	# Call the Uninstall script
	[ -f $(RUST_UNINSTALL) ] && \
	  $(INCLUDE_DIR)/shell.sh $(RUST_UNINSTALL) || echo No Uninstall

	# Remove the Symlink and CARGO_HOME directory
	rm -rf $(BUILD_DIR_HOST)/rust $(CARGO_HOME)
endef

# Makes and then packages the dist artifacts
define Host/Compile
	cd $(HOST_BUILD_DIR) && \
	  $(PYTHON) x.py --config ./config.toml dist

	$(call Host/PackageDist)
endef

# Distribution Artifacts are packaged by Host/PackageDist
# We just need to extract and install
define Host/Install
	$(TAR) -C $(RUST_TMP_DIR) -xJf $(DL_DIR)/$(RUST_INSTALL_HOST_FILENAME) && \
	$(TAR) -C $(RUST_TMP_DIR) -xJf $(DL_DIR)/$(RUST_INSTALL_TARGET_FILENAME)

	cd $(RUST_TMP_DIR) && \
	  find -iname "*.xz" -exec tar -xJf {} ";" && \
	  find ./* -type f -name install.sh -execdir sh {} --prefix=$(STAGING_DIR_HOST) --disable-ldconfig \;
endef

# Packages the Distribution Artifacts into HOST and TARGET bundles.
define Host/PackageDist
	cd $(HOST_BUILD_DIR)/build/dist && \
	  $(TAR) -cJf $(DL_DIR)/$(RUST_INSTALL_TARGET_FILENAME) \
	  rust-*-$(RUSTC_TARGET_ARCH).tar.xz

	cd $(HOST_BUILD_DIR)/build/dist && \
	  $(TAR) -cJf $(DL_DIR)/$(RUST_INSTALL_HOST_FILENAME) \
	  --exclude rust-*-$(RUSTC_TARGET_ARCH).tar.xz *.xz
endef

define Package/rust
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=Rust Programming Language Compiler
  URL:=https://www.rust-lang.org/
  DEPENDS:=@BROKEN @(aarch64||arm||mips||mips64||mipsel||x86_64) \
    +python3 +pkg-config +libopenssl +libyaml +libyaml-cpp +libunwind +openssl-util +python3-yaml
endef

define Package/rust/description
  Rust lang
endef

define Package/rust/config
	source "$(SOURCE)/Config.in"
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,rust))

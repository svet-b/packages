# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=rust
PKG_VERSION:=1.58.0
PKG_RELEASE:=1

PKG_LICENSE:=Apache-2.0 MIT
PKG_LICENSE_FILES:=LICENSE-APACHE LICENSE-MIT

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/rust-lang/rust.git
PKG_SOURCE_DATE:=2022-01-13
PKG_SOURCE_VERSION:=02072b482a8b5357f7fb5e5637444ae30e423c40
#PKG_MIRROR_HASH:=de66268e13fa9cf3222d10ae3249dae88ca37f8b7aa0a5067003ef14fa2108f5

include $(INCLUDE_DIR)/cmake.mk
include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/package.mk

HOST_BUILD_DEPENDS:=python3/host
PKG_BUILD_DEPENDS:=rust/host
CMAKE_INSTALL:=1

# These are environment variables that are used by other packages to
# define where rustc/cargo are kept.
include ./rust_targets.mk

ifeq ($(ARCH),powerpc)
CONFIGURE_ARGS += \
  --set=llvm.cflags=-D__ppc__ \
  --set=llvm.cxxflags=-D__ppc__
endif

# Because we override CONFIGURE_ARGS, this needs to go here.
include ./rust_config.mk

CARGO_HOME:=$(TOOLCHAIN_DIR)
RUST_TMP_DIR:=$(TMP_DIR)/rust-install
RUST_INSTALL_HOST_FILENAME:=$(PKG_NAME)-$(PKG_VERSION)-$(RUSTC_HOST_ARCH)-install.tar.xz
RUST_INSTALL_TARGET_FILENAME:=$(PKG_NAME)-$(PKG_VERSION)-$(RUSTC_TARGET_ARCH)-install.tar.xz

# Rust-lang installs a uninstall script
RUST_UNINSTALL:=$(CARGO_HOME)/lib/rustlib/uninstall.sh

# This checks to see if the dist installation already exists
IS_RUST_HOST_BINARY:=$(or $(and $(wildcard $(DL_DIR)/$(RUST_INSTALL_HOST_FILENAME)),true),false)
IS_RUST_TARGET_BINARY:=$(or $(and $(wildcard $(DL_DIR)/$(RUST_INSTALL_TARGET_FILENAME)),true),false)
IS_RUSTC_INSTALLED:=$(or $(and $(wildcard $(CARGO_HOME)/bin/rustc),true),false)
IS_CARGO_INSTALLED:=$(or $(and $(wildcard $(CARGO_HOME)/bin/cargo),true),false)

include ./rust_host.mk
include ./rust_build.mk

define Package/rust
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=Rust Programming Language Compiler
  URL:=https://www.rust-lang.org/
  DEPENDS:=@(aarch64||arm||mips||mips64||mipsel||x86_64) \
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

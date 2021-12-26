define Build/Configure
	MUSL_CONFIGURE_ARGS= \
	  --set=target.$(RUSTC_TARGET_ARCH).linker=$(TARGET_CC_NOCACHE) \
	  --set=target.$(RUSTC_TARGET_ARCH).cc=$(TARGET_CC_NOCACHE) \
	  --set=target.$(RUSTC_TARGET_ARCH).cxx=$(TARGET_CXX_NOCACHE) \
	  --set=target.$(RUSTC_TARGET_ARCH).ar=$(TARGET_AR) \
	  --set=target.$(RUSTC_TARGET_ARCH).ranlib=$(TARGET_RANLIB) \
	  --set=target.$(RUSTC_TARGET_ARCH).crt-static=false \
	  --set=target.$(RUSTC_TARGET_ARCH).musl-root=$(TOOLCHAIN_DIR)

	RUST_CONFIGURE_ARGS= \
	  --target=$(RUSTC_TARGET_ARCH) \
	  --build=$(RUSTC_HOST_ARCH) \
	  --host=$(RUSTC_TARGET_ARCH) \
	  --prefix=$(CONFIGURE_PREFIX) \
	  --bindir=$(CONFIGURE_PREFIX)/bin \
	  --libdir=$(CONFIGURE_PREFIX)/lib \
	  --sysconfdir=$(CONFIGURE_PREFIX)/etc \
	  --datadir=$(CONFIGURE_PREFIX)/share \
	  --mandir=$(CONFIGURE_PREFIX)/man \
	  --release-channel=nightly \
	  --set=llvm.link-shared=true \
	  --enable-lld \
	  --enable-vendor \
	  --enable-llvm-link-shared \
	  --enable-full-tools \
	  --enable-missing-tools \
	  --dist-compression-formats=xz \
	  $(MUSL_CONFIGURE_ARGS)

	# Required because OpenWrt Default CONFIGURE_ARGS contain extra
	# args that cause errors
	cd $(PKG_BUILD_DIR) && \
	./configure $(RUST_CONFIGURE_ARGS)
endef

define Build/Compile
	#[ -e $(PKG_BUILD_DIR)/build/x86_64-unknown-linux-gnu/llvm/llvm-finished-building ] && \
	#
	#  rm $(PKG_BUILD_DIR)/build/x86_64-unknown-linux-gnu/llvm/llvm-finished-building

	cd $(PKG_BUILD_DIR) && \
	   $(PYTHON) x.py --config ./config.toml dist
endef


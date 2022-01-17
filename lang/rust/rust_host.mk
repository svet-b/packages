
# Define empty Default Host/ sections - override later depending
# on the situation
# Host/Prepare can always be called (for now)
define Host/Prepare
	# Allows outside packages to call $$(BUILD_DIR_HOST)/rust as the dir
	# rather than needing the version number.
	[ -L $(BUILD_DIR_HOST)/rust ] || \
	  (cd $(BUILD_DIR_HOST); ln -s "$(PKG_NAME)-$(PKG_VERSION)" rust)

	[ -d $(RUST_TMP_DIR) ] || \
	  mkdir -p $(RUST_TMP_DIR)
endef

define Host/Configure
	true
endef

define Host/Compile
	true
endef

define Host/Install
	true
endef

define Host/Uninstall
	[ -f $(RUST_UNINSTALL) ] && \
	  $(RUST_UNINSTALL) || echo No Uninstall Found
	
	rm -rf $(BUILD_DIR_HOST)/rust
	
	rm -rf $(RUST_TMP_DIR)
endef

define Host/PackageDist
	cd $(HOST_BUILD_DIR)/build/dist && \
	  $(TAR) -cJf $(DL_DIR)/$(RUST_INSTALL_TARGET_FILENAME) \
	  rust-*-$(RUSTC_TARGET_ARCH).tar.xz

	cd $(HOST_BUILD_DIR)/build/dist && \
	  $(TAR) -cJf $(DL_DIR)/$(RUST_INSTALL_HOST_FILENAME) \
	  --exclude rust-*-$(RUSTC_TARGET_ARCH).tar.xz *.xz
endef

##############################################################################
# Is cargo installed to $$(CARGO_HOME)/bin?  If not, compile
##############################################################################
ifneq ($(IS_CARGO_INSTALLED), true) 
  ifeq ($(IS_RUST_HOST_BINARY), true)
    override define Host/Install
    	  $(TAR) -C $(RUST_TMP_DIR) -xvJf $(DL_DIR)/$(RUST_INSTALL_HOST_FILENAME) && \
    	  $(TAR) -C $(RUST_TMP_DIR) -xvJf $(DL_DIR)/$(RUST_INSTALL_TARGET_FILENAME) && \
    	  cd $(RUST_TMP_DIR) && \
    	    find -iname "*.xz" -exec tar -vxJf {} ";" && \
    	    find ./* -type f -name install.sh -execdir sh {} --prefix=$(CARGO_HOME) --disable-ldconfig \;
    endef
  else
    override define Host/Prepare
		# Allows outside packages to call $$(BUILD_DIR_HOST)/rust as the dir
		# rather than needing the version number.
		[ -L $(BUILD_DIR_HOST)/rust ] || \
		(cd $(BUILD_DIR_HOST); ln -s "$(PKG_NAME)-$(PKG_VERSION)" rust)
		
		[ -d $(RUST_TMP_DIR) ] || \
		mkdir -p $(RUST_TMP_DIR)
		
		$(call Host/Prepare/Default)
    endef

    override define Host/Configure
#		MUSL_CONFIGURE_ARGS=--set=target.${RUSTC_TARGET_ARCH}.linker=${TARGET_CC_NOCACHE} --set=target.${RUSTC_TARGET_ARCH}.cc=${TARGET_CC_NOCACHE} --set=target.${RUSTC_TARGET_ARCH}.cxx=${TARGET_CXX_NOCACHE} --set=target.${RUSTC_TARGET_ARCH}.ar=${TARGET_AR} --set=target.${RUSTC_TARGET_ARCH}.ranlib=${TARGET_RANLIB} --set=target.${RUSTC_TARGET_ARCH}.crt-static=false --set=target.${RUSTC_TARGET_ARCH}.musl-root=${TOOLCHAIN_DIR} --set=target.${RUSTC_TARGET_ARCH}.musl-libdir=${TOOLCHAIN_DIR}/lib
		RUST_CONFIGURE_ARGS="--target=${RUSTC_TARGET_ARCH} --build=${RUSTC_HOST_ARCH} --host=${RUSTC_TARGET_ARCH} --prefix=${CARGO_HOME} --bindir=${CARGO_HOME}/bin --libdir=${CARGO_HOME}/lib --sysconfdir=${CARGO_HOME}/etc --datadir=${CARGO_HOME}/share --mandir=${CARGO_HOME}/man --release-channel=stable --set=llvm.link-shared=true --enable-lld --enable-vendor --enable-llvm-link-shared --enable-full-tools --enable-missing-tools --dist-compression-formats=xz ${MUSL_CONFIGURE_ARGS} --set=target.${RUSTC_TARGET_ARCH}.linker=${TARGET_CC_NOCACHE} --set=target.${RUSTC_TARGET_ARCH}.cc=${TARGET_CC_NOCACHE} --set=target.${RUSTC_TARGET_ARCH}.cxx=${TARGET_CXX_NOCACHE} --set=target.${RUSTC_TARGET_ARCH}.ar=${TARGET_AR} --set=target.${RUSTC_TARGET_ARCH}.ranlib=${TARGET_RANLIB} --set=target.${RUSTC_TARGET_ARCH}.crt-static=false --set=target.${RUSTC_TARGET_ARCH}.musl-root=${TOOLCHAIN_DIR} --set=target.${RUSTC_TARGET_ARCH}.musl-libdir=${TOOLCHAIN_DIR}/lib"

		# Required because OpenWrt Default CONFIGURE_ARGS contain extra
		# args that cause errors
		cd $(HOST_BUILD_DIR) && \
		  ./configure ${RUST_CONFIGURE_ARGS}
#		  ./configure --target=$(RUSTC_TARGET_ARCH) --build=$(RUSTC_HOST_ARCH) --host=$(RUSTC_TARGET_ARCH) --prefix=$(CARGO_HOME) --bindir=$(CARGO_HOME)/bin --libdir=$(CARGO_HOME)/lib --sysconfdir=$(CARGO_HOME)/etc --datadir=$(CARGO_HOME)/share --mandir=$(CARGO_HOME)/man --release-channel=stable --set=llvm.link-shared=true --enable-lld --enable-vendor --enable-llvm-link-shared --enable-full-tools --enable-missing-tools --dist-compression-formats=xz --set=target.$(RUSTC_TARGET_ARCH).linker=$(TARGET_CC_NOCACHE) --set=target.$(RUSTC_TARGET_ARCH).cc=$(TARGET_CC_NOCACHE) --set=target.$(RUSTC_TARGET_ARCH).cxx=$(TARGET_CXX_NOCACHE) --set=target.$(RUSTC_TARGET_ARCH).ar=$(TARGET_AR) --set=target.$(RUSTC_TARGET_ARCH).ranlib=$(TARGET_RANLIB) --set=target.$(RUSTC_TARGET_ARCH).crt-static=false --set=target.$(RUSTC_TARGET_ARCH).musl-root=$(TOOLCHAIN_DIR) --set=target.$(RUSTC_TARGET_ARCH).musl-libdir=$(TOOLCHAIN_DIR)/lib
    endef
  
    override define Host/Compile
		cd $(HOST_BUILD_DIR) && \
		$(PYTHON) x.py build -i --config ./config.toml library/std
		
		$(call Host/PackageDist)
    endef
  
    override define Host/Install
		# This needs to identify, extract, and install the dist
		$(TAR) -C $(RUST_TMP_DIR) -xvJf $(DL_DIR)/$(RUST_INSTALL_HOST_FILENAME)
		$(TAR) -C $(RUST_TMP_DIR) -xvJf $(DL_DIR)/$(RUST_INSTALL_TARGET_FILENAME)
		
		cd $(RUST_TMP_DIR) && \
		find -iname "*.xz" -exec tar -v -x -J -f {} ";" && \
		find ./* -type f -name install.sh -execdir sh {} --prefix=$(CARGO_HOME) \
		  --disable-ldconfig \;
    endef
  endif
endif

##############################################################################
# Is rustc installed to $$(CARGO_HOME)/bin?  If not, compile
##############################################################################
ifneq ($(IS_RUSTC_INSTALLED), true)
  ifeq ($(IS_RUST_HOST_BINARY), true)
    override define Host/Install
		# This needs to identify, extract, and install the dist
		$(TAR) -C $(RUST_TMP_DIR) -xvJf $(DL_DIR)/$(RUST_INSTALL_HOST_FILENAME)
		$(TAR) -C $(RUST_TMP_DIR) -xvJf $(DL_DIR)/$(RUST_INSTALL_TARGET_FILENAME)
		
		cd $(RUST_TMP_DIR) && \
		find -iname "*.xz" -exec tar -v -x -J -f {} ";" && \
		find ./* -type f -name install.sh -execdir sh {} --prefix=$(CARGO_HOME) \
		  --disable-ldconfig \;
    endef
  else
    override define Host/Configure
#		MUSL_CONFIGURE_ARGS=--set=target.${RUSTC_TARGET_ARCH}.linker=${TARGET_CC_NOCACHE} --set=target.${RUSTC_TARGET_ARCH}.cc=${TARGET_CC_NOCACHE} --set=target.${RUSTC_TARGET_ARCH}.cxx=${TARGET_CXX_NOCACHE} --set=target.${RUSTC_TARGET_ARCH}.ar=${TARGET_AR} --set=target.${RUSTC_TARGET_ARCH}.ranlib=${TARGET_RANLIB} --set=target.${RUSTC_TARGET_ARCH}.crt-static=false --set=target.${RUSTC_TARGET_ARCH}.musl-root=${TOOLCHAIN_DIR} --set=target.${RUSTC_TARGET_ARCH}.musl-libdir=${TOOLCHAIN_DIR}/lib
#		RUST_CONFIGURE_ARGS=--target=${RUSTC_TARGET_ARCH} --build=${RUSTC_HOST_ARCH} --host=${RUSTC_TARGET_ARCH} --prefix=${CARGO_HOME} --bindir=${CARGO_HOME}/bin --libdir=${CARGO_HOME}/lib --sysconfdir=${CARGO_HOME}/etc --datadir=${CARGO_HOME}/share --mandir=${CARGO_HOME}/man --release-channel=stable --set=llvm.link-shared=true --enable-lld --enable-vendor --enable-llvm-link-shared --enable-full-tools --enable-missing-tools --dist-compression-formats=xz ${MUSL_CONFIGURE_ARGS} \
	  
		# Required because OpenWrt Default CONFIGURE_ARGS contain extra
		# args that cause errors
		cd $(HOST_BUILD_DIR) && \
		  ./configure --target=$(RUSTC_TARGET_ARCH) --build=$(RUSTC_HOST_ARCH) --host=$(RUSTC_TARGET_ARCH) --prefix=$(CARGO_HOME) --bindir=$(CARGO_HOME)/bin --libdir=$(CARGO_HOME)/lib --sysconfdir=$(CARGO_HOME)/etc --datadir=$(CARGO_HOME)/share --mandir=$(CARGO_HOME)/man --release-channel=stable --set=llvm.link-shared=true --enable-lld --enable-vendor --enable-llvm-link-shared --enable-full-tools --enable-missing-tools --dist-compression-formats=xz --set=target.$(RUSTC_TARGET_ARCH).linker=$(TARGET_CC_NOCACHE) --set=target.$(RUSTC_TARGET_ARCH).cc=$(TARGET_CC_NOCACHE) --set=target.$(RUSTC_TARGET_ARCH).cxx=$(TARGET_CXX_NOCACHE) --set=target.$(RUSTC_TARGET_ARCH).ar=$(TARGET_AR) --set=target.$(RUSTC_TARGET_ARCH).ranlib=$(TARGET_RANLIB) --set=target.$(RUSTC_TARGET_ARCH).crt-static=false --set=target.$(RUSTC_TARGET_ARCH).musl-root=$(TOOLCHAIN_DIR) --set=target.$(RUSTC_TARGET_ARCH).musl-libdir=$(TOOLCHAIN_DIR)/lib
#		./configure ${RUST_CONFIGURE_ARGS}
    endef
  
    override define Host/Compile
		cd $(HOST_BUILD_DIR) && \
		$(PYTHON) x.py build -i --config ./config.toml library/std
		
		$(call Host/PackageDist)
    endef
  
    override define Host/Install
		# This needs to identify, extract, and install the dist
		$(TAR) -C $(RUST_TMP_DIR) -xvJf $(DL_DIR)/$(RUST_INSTALL_HOST_FILENAME)
		$(TAR) -C $(RUST_TMP_DIR) -xvJf $(DL_DIR)/$(RUST_INSTALL_TARGET_FILENAME)
		
		cd $(RUST_TMP_DIR) && \
		find -iname "*.xz" -exec tar -v -x -J -f {} ";" && \
		find ./* -type f -name install.sh -execdir sh {} --prefix=$(CARGO_HOME) \
		  --disable-ldconfig \;
    endef
  endif
endif

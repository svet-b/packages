# These are environment variables that are used by other packages to
# define where rustc/cargo are kept.
CONFIG_HOST_SUFFIX:=$(shell cut -d"-" -f4 <<<"$(GNU_HOST_NAME)")
RUSTC_HOST_ARCH:=$(HOST_ARCH)-unknown-linux-$(CONFIG_HOST_SUFFIX)

ifeq ($(CONFIG_ARCH), $(filter "mips64%", $(CONFIG_ARCH)))
  RUST_TARGET_SUFFIX:="muslabi64"
endif

ifeq ($(CONFIG_ARCH), "mips")
  RUST_TARGET_SUFFIX:="musl"
endif

ifeq ($(CONFIG_ARCH), "arm")

ifeq ($(CONFIG_ARCH), "arm")
  ifeq ($(CONFIG_arm_v7), y)
    ARCH=armv7
  endif

  # Default to musleabi
  RUST_TARGET_SUFFIX:="musleabi"

  ifneq ($(filter fpu, $(FEATURES)),)
    RUST_TARGET_SUFFIX:="musleabihf"
  endif

  # If the CPU_TYPE contains neon/vfp flags, set hf
  ifneq ($(findstring vfp, $(CONFIG_CPU_TYPE)),)
    RUST_TARGET_SUFFIX:="musleabihf"
  endif
  ifneq ($(findstring neon, $(CONFIG_CPU_TYPE)),)
    RUST_TARGET_SUFFIX:="musleabihf"
  endif

  # Figure out if CPU_SUBTYPE is a thing, then filter by hf
  ifneq ($(CONFIG_CPU_SUBTYPE),)
    ifeq ($(CONFIG_CPU_SUBTYPE), $(filter vfp%, $(CONFIG_CPU_SUBTYPE)))
      RUST_TARGET_SUFFIX:="musleabihf"
    endif
    ifeq ($(CONFIG_CPU_SUBTYPE), $(filter neon%, $(CONFIG_CPU_SUBTYPE)))
      RUST_TARGET_SUFFIX:="musleabihf"
    endif
  endif
endif

RUSTC_TARGET_ARCH:=$(ARCH)-unknown-linux-$(patsubst "%",%,$(RUST_TARGET_SUFFIX))
#RUSTC_TARGET_ARCH:=$(REAL_GNU_TARGET_NAME)
#CARGO_HOME:=$(TOOLCHAIN_DIR)


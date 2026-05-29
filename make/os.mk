IS_WINDOWS := $(if $(filter Windows_NT,$(OS)),yes,$(if $(or $(ComSpec),$(COMSPEC),$(WINDIR),$(windir)),yes,no))

ifeq ($(IS_WINDOWS),yes)
	CURRENT_ARCH := amd64
	ifneq (,$(findstring ARM64,$(PROCESSOR_ARCHITECTURE) $(PROCESSOR_ARCHITEW6432)))
		CURRENT_ARCH := arm64
	endif
	UNAME := windows
	OS := Windows
	OS_ID := windows
	OS_ID_LIKE := windows
	OS_VERSION := $(shell ver)
else
	OS_RELEASE_FILE := /etc/os-release
	OS_RELEASE_FILE_EXISTS := $(if $(wildcard $(OS_RELEASE_FILE)),yes,no)
	UNAME := $(shell uname | tr A-Z a-z 2>/dev/null)

	# Detect OS and related information
ifeq ($(UNAME),darwin)
	OS_ID := macos
	OS_VERSION_MAJOR := $(shell sw_vers -productVersion | cut -c1-2)
	OS_VERSION := $(shell sw_vers -productVersion | cut -c1-6)
ifeq ($(OS_VERSION_MAJOR),26)
	OS := macOS Tahoe
else ifeq ($(OS_VERSION_MAJOR),15)
	OS := macOS Sequoia
else ifeq ($(OS_VERSION_MAJOR),14)
	OS := macOS Sonoma
else ifeq ($(OS_VERSION_MAJOR),13)
	OS := macOS Ventura
else ifeq ($(OS_VERSION_MAJOR),12)
	OS := macOS Monterey
else
	OS := macOS $(OS_VERSION)
	OS_ID := UNKNOWN
endif
	OS_ID_LIKE := $(UNAME)
else ifeq ($(OS_RELEASE_FILE_EXISTS),yes)
	# Ubuntu 18.04.3 LTS (Bionic Beaver) / Manjaro Linux / Arch Linux
	OS := $(shell . $(OS_RELEASE_FILE) && echo "$${PRETTY_NAME}")
	# ubuntu / arch / manjaro
	OS_ID := $(shell . $(OS_RELEASE_FILE) && echo "$${ID}")
	# debian / arch
	OS_ID_LIKE := $(shell . $(OS_RELEASE_FILE) && echo "$${ID_LIKE}")
ifeq ($(OS_ID),arch)
	OS_ID_LIKE := arch
endif
	# e.g. Ubuntu can give: 18.04
	OS_VERSION := $(shell . $(OS_RELEASE_FILE) && echo "$${VERSION_ID}")
else
	OS := $(shell uname -s)
	OS_ID := UNKNOWN
	OS_ID_LIKE := UNKNOWN
	OS_VERSION := UNKNOWN
endif
endif

ifneq ($(WSL_INTEROP),)
	WSL := yes
else
	WSL := no
endif

ifeq ($(OS_ID),UNKNOWN)
ifeq ($(WSL),yes)
$(error OS $(OS) not supported. WSL_INTEROP is $(WSL_INTEROP))
else
$(error OS $(OS) not supported)
endif
endif

ifeq ($(OS_ID_LIKE),darwin)
	BREW_BIN := $(shell command -v brew || echo no)
endif

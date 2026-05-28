CURRENT_ARCH := amd64
ifneq (,$(findstring ARM64,$(PROCESSOR_ARCHITECTURE) $(PROCESSOR_ARCHITEW6432)))
CURRENT_ARCH := arm64
endif
UNAME := windows

OS := Windows
OS_ID := windows
OS_ID_LIKE := windows
OS_VERSION := $(shell ver)

ifneq ($(WSL_INTEROP),)
	WSL := yes
else
	WSL := no
endif

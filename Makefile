.DEFAULT_GOAL := help
PHONY :=
PROJECT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
PROJECT_ROOT := $(abspath $(PROJECT_DIR))
MAKE_LIB_DIR := $(PROJECT_ROOT)/make

IS_WINDOWS := $(if $(filter Windows_NT,$(OS)),yes,$(if $(or $(ComSpec),$(COMSPEC),$(WINDIR),$(windir)),yes,no))
ifeq ($(IS_WINDOWS),yes)
	SHELL := cmd
	.SHELLFLAGS := /C
	PS7 := pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command
else
	SHELL := /bin/bash
endif

# Include Stonehenge ENV variables
include $(PROJECT_ROOT)/.env

# Include Stonehenge makefiles
include $(MAKE_LIB_DIR)/stonehenge.mk

.PHONY: $(PHONY)

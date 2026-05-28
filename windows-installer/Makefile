.DEFAULT_GOAL := help
PHONY :=
PROJECT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ROOT_DIR := $(abspath $(PROJECT_DIR)/..)
SHELL := cmd
.SHELLFLAGS := /C
PS7 := pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command

# Include Stonehenge env variables from repository root
include $(ROOT_DIR)/.env

# Include Windows-compatible makefiles
include $(PROJECT_DIR)/make/stonehenge.mk

.PHONY: $(PHONY)

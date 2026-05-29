PHONY += debug
debug:
	$(call step,Debug:)
	$(call val,Stonehenge version,$(STONEHENGE_VERSION))
	$(call val,OS,$(OS))
	$(call val,ARCH,$(CURRENT_ARCH))
	$(call val,OS_ID,$(OS_ID))
	$(call val,OS_ID_LIKE,$(OS_ID_LIKE))
	$(call val,OS_VERSION,$(OS_VERSION))
	$(call val,WSL,$(WSL))
	$(call val,Docker installed,$(DOCKER_BIN))
	$(call val,Docker version,$(shell docker --version 2>NUL))
	$(call val,Docker domain,$(DOCKER_DOMAIN))
	$(call val,Docker network name,$(NETWORK_NAME))
	$(call val,mkcert installed,$(MKCERT_BIN))
ifeq ($(OS_ID_LIKE),darwin)
	$(call val,Homebrew installed,$(BREW_BIN))
endif

PHONY += help
help: ## Print this help

ifeq ($(OS_ID),windows)
	$(call step,Available make commands for Stonehenge:)
	@$(PS7) "$$files = Get-ChildItem -Path '$(PROJECT_ROOT)' -Recurse -Include 'Makefile','*.mk' | Select-Object -ExpandProperty FullName; $$rows = foreach ($$f in $$files) { Select-String -Path $$f -Pattern '^[a-zA-Z_\-]+:.*##\s*' }; foreach ($$r in ($$rows | ForEach-Object { if ($$_.Line -match '^([a-zA-Z_\-]+):.*##\s*(.+)$$') { [PSCustomObject]@{Target=$$Matches[1]; Description=$$Matches[2]} } } | Sort-Object Target -Unique)) { '{0,-30} {1}' -f $$r.Target, $$r.Description }"
else
	$(call step,Available make commands for Stonehenge:)
	@cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort
endif

PHONY += check-scripts
check-scripts:

ifeq ($(OS_ID),windows)
	@$(PS7) "if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) { Invoke-ScriptAnalyzer -Path install.ps1 } else { Write-Host 'PSScriptAnalyzer is not installed' }"
else
	@shellcheck install.sh && echo "All good"
endif

PHONY += ping
ping: ## Ping docker.so domain

ifeq ($(OS_ID),windows)
	$(call step,Domain $(DOCKER_DOMAIN) resolves to:)
	@$(PS7) "try { (Resolve-DnsName '$(DOCKER_DOMAIN)' -Type A -ErrorAction Stop | Select-Object -ExpandProperty IPAddress -First 1) } catch { 'Unable to resolve $(DOCKER_DOMAIN)' }"
	$(call step,Domain foobar.$(DOCKER_DOMAIN) resolves to:)
	@$(PS7) "try { (Resolve-DnsName 'foobar.$(DOCKER_DOMAIN)' -Type A -ErrorAction Stop | Select-Object -ExpandProperty IPAddress -First 1) } catch { 'Unable to resolve foobar.$(DOCKER_DOMAIN)' }"
else
	$(call step,Domain $(DOCKER_DOMAIN) resolves to:)
	@ping -q -c 1 -t 1 $(DOCKER_DOMAIN) | grep PING | sed -e "s/).*//" | sed -e "s/.*(//"
	$(call step,Domain foobar.$(DOCKER_DOMAIN) resolves to:)
	@ping -q -c 1 -t 1 foobar.$(DOCKER_DOMAIN) | grep PING | sed -e "s/).*//" | sed -e "s/.*(//"
endif

PHONY += debug-arch
debug-arch:

ifeq ($(OS_ID),windows)
	@$(MAKE) debug OS="Arch Linux" OS_ID=arch OS_ID_LIKE=arch OS_VERSION="rolling" CURRENT_ARCH=arm64
else
	@make debug OS_RELEASE_FILE=tests/os-release.arch UNAME=Linux
endif

PHONY += debug-manjaro
debug-manjaro:

ifeq ($(OS_ID),windows)
	@$(MAKE) debug OS="Manjaro Linux" OS_ID=manjaro OS_ID_LIKE=arch OS_VERSION="rolling" CURRENT_ARCH=amd64
else
	@make debug OS_RELEASE_FILE=tests/os-release.arch-manjaro UNAME=Linux
endif

ifeq ($(OS_ID),windows)
define step
	@echo.
	@echo [STEP] ${1}
	@echo.
endef

define item
	@echo ${1}
endef

define success
	@echo.
	@echo ${1} ${2}
	@echo.
endef

define val
	@echo ${1}: ${2}
endef

define warn
	@echo.
	@echo ${1} ${2}
	@echo.
endef
else
# Colors
NO_COLOR=\033[0m
GREEN=\033[0;32m
RED=\033[0;31m
YELLOW=\033[0;33m

define download
	@curl -s -# -L ${1} -o ${2} && test -f ${2} && echo "Downloaded ${2} from ${1}" || echo "Error: Downloading ${1} failed"
endef

define step
	@printf "\n${YELLOW}⚡ ${1}${NO_COLOR}\n\n"
endef

define item
	@echo "${1}"
endef

define success
	@printf "\n${GREEN}${1}${NO_COLOR} ${2}\n\n"
endef

define val
	@printf "${YELLOW}${1}:${NO_COLOR} ${2}\n"
endef

define warn
	@printf "\n${RED}${1}${NO_COLOR} ${2}\n\n"
endef
endif

#
# Experimental: don't list them with help
#

#
#
#
PHONY += lineinfile
ifeq ($(OS_ID),windows)
lineinfile: FILE := $(TEMP)/foobar.conf
else
lineinfile: FILE := /tmp/foobar.conf
endif
lineinfile: LINE := foobar=foo
lineinfile:
	$(call step,Add a line to a file. Override line with: make lineinfile LINE=furbar)

ifeq ($(OS_ID),windows)
	$(call lineinfile,$(FILE),$(LINE))
	@type "$(FILE)"
else
	@touch $(FILE)
	$(call lineinfile,$(FILE),$(LINE))
	@cat $(FILE)
endif

ifeq ($(OS_ID),windows)
define lineinfile
	@if not exist "${1}" type NUL > "${1}"
	@findstr /X /C:"${2}" "${1}" >NUL 2>&1 || echo ${2}>>"${1}"
endef
else
define lineinfile
	grep -qF -- "${2}" ${1} || echo "${2}" >> ${1}
endef
endif

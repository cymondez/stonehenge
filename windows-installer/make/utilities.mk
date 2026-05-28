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

PHONY += help
help: ## Print this help
	$(call step,Available make commands for Stonehenge:)
	@$(PS7) "$$files = Get-ChildItem -Path './windows-installer' -Recurse -Include 'Makefile','*.mk' | Select-Object -ExpandProperty FullName; $$rows = foreach ($$f in $$files) { Select-String -Path $$f -Pattern '^[a-zA-Z_\-]+:.*##\s*' }; foreach ($$r in ($$rows | ForEach-Object { if ($$_.Line -match '^([a-zA-Z_\-]+):.*##\s*(.+)$$') { [PSCustomObject]@{Target=$$Matches[1]; Description=$$Matches[2]} } } | Sort-Object Target -Unique)) { '{0,-30} {1}' -f $$r.Target, $$r.Description }"

PHONY += check-scripts
check-scripts:
	@$(PS7) "if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) { Invoke-ScriptAnalyzer -Path install.ps1 } else { Write-Host 'PSScriptAnalyzer is not installed' }"

PHONY += ping
ping: ## Ping docker.so domain
	$(call step,Domain $(DOCKER_DOMAIN) resolves to:)
	@$(PS7) "try { (Resolve-DnsName '$(DOCKER_DOMAIN)' -Type A -ErrorAction Stop | Select-Object -ExpandProperty IPAddress -First 1) } catch { 'Unable to resolve $(DOCKER_DOMAIN)' }"
	$(call step,Domain foobar.$(DOCKER_DOMAIN) resolves to:)
	@$(PS7) "try { (Resolve-DnsName 'foobar.$(DOCKER_DOMAIN)' -Type A -ErrorAction Stop | Select-Object -ExpandProperty IPAddress -First 1) } catch { 'Unable to resolve foobar.$(DOCKER_DOMAIN)' }"

PHONY += debug-arch
debug-arch:
	@$(MAKE) debug OS="Arch Linux" OS_ID=arch OS_ID_LIKE=arch OS_VERSION="rolling" CURRENT_ARCH=arm64

PHONY += debug-manjaro
debug-manjaro:
	@$(MAKE) debug OS="Manjaro Linux" OS_ID=manjaro OS_ID_LIKE=arch OS_VERSION="rolling" CURRENT_ARCH=amd64

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

PHONY += lineinfile
lineinfile: FILE := $(TEMP)/foobar.conf
lineinfile: LINE := foobar=foo
lineinfile:
	$(call step,Add a line to a file. Override line with: make lineinfile LINE=furbar)
	$(call lineinfile,$(FILE),$(LINE))
	@type "$(FILE)"

define lineinfile
	@if not exist "${1}" type NUL > "${1}"
	@findstr /X /C:"${2}" "${1}" >NUL 2>&1 || echo ${2}>>"${1}"
endef

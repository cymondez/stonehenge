MKCERT_REPO := https://github.com/FiloSottile/mkcert
MKCERT_VERSION := v1.4.4

UP_PRE_TARGETS += mkcert-install certs
POST_DOWN_ACTIONS += certs-uninstall

ifeq ($(OS_ID),windows)
MKCERT_BIN := $(shell where mkcert >NUL 2>&1 && echo yes || echo no)
MKCERT_CAROOT := $(PROJECT_ROOT)/certs
SH_CERTS_PATH := $(PROJECT_ROOT)/certs

PHONY += mkcert-install
mkcert-install: ## Install mkcert
	$(call step,Install mkcert on Windows)
	@$(PS7) "$$mkcert = (Get-Command mkcert -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue); if (-not $$mkcert) { $$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator); if (-not $$isAdmin) { Write-Error 'Administrator terminal is required to install mkcert with Chocolatey. Re-run in elevated PowerShell: choco install mkcert -y'; exit 1 }; choco install mkcert -y | Out-Null; $$mkcert = (Get-Command mkcert -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue) }; if (-not $$mkcert) { $$chocoRoot = if ($$env:ChocolateyInstall) { $$env:ChocolateyInstall } else { 'C:\\ProgramData\\chocolatey' }; $$mkcert = Join-Path $$chocoRoot 'bin\\mkcert.exe' }; if (-not (Test-Path $$mkcert)) { Write-Error 'mkcert install failed or not found. Please run choco install mkcert -y in elevated PowerShell.'; exit 1 }; Write-Host ('mkcert ready: ' + $$mkcert)"

PHONY += certs
certs: --certs-install-ca --certs-dockerso --certs-traefikme ## Install certs

PHONY += certs-uninstall
certs-uninstall: ## Uninstall certs
	$(call step,Uninstall local CA...)
	@$(PS7) "$$env:CAROOT = '$(MKCERT_CAROOT)'; $$mkcert = (Get-Command mkcert -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue); if (-not $$mkcert) { $$chocoRoot = if ($$env:ChocolateyInstall) { $$env:ChocolateyInstall } else { 'C:\\ProgramData\\chocolatey' }; $$mkcert = Join-Path $$chocoRoot 'bin\\mkcert.exe' }; if (Test-Path $$mkcert) { & $$mkcert -uninstall | Out-Null; if ($$LASTEXITCODE -ne 0) { Write-Host 'No CA found...' } } else { Write-Host 'mkcert not found, skip uninstall' }; Remove-Item -Path '$(SH_CERTS_PATH)/*.crt','$(SH_CERTS_PATH)/*.key','$(SH_CERTS_PATH)/*.pem' -Force -ErrorAction SilentlyContinue"

PHONY += --certs-install-ca
--certs-install-ca:
	$(call step,Create local CA...)
	@$(PS7) "$$env:CAROOT = '$(MKCERT_CAROOT)'; $$mkcert = (Get-Command mkcert -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue); if (-not $$mkcert) { $$chocoRoot = if ($$env:ChocolateyInstall) { $$env:ChocolateyInstall } else { 'C:\\ProgramData\\chocolatey' }; $$mkcert = Join-Path $$chocoRoot 'bin\\mkcert.exe' }; if (-not (Test-Path $$mkcert)) { Write-Error 'mkcert not found. Run make mkcert-install first.'; exit 1 }; & $$mkcert -install"

PHONY += --certs-dockerso
--certs-dockerso: SH_CERT_FILENAME := $(DOCKER_DOMAIN)
--certs-dockerso: CERT := $(SH_CERTS_PATH)/$(SH_CERT_FILENAME)
--certs-dockerso:
	$(call step,Create $(SH_CERT_FILENAME) certificate in ./certs...)
	@$(PS7) "$$env:CAROOT = '$(MKCERT_CAROOT)'; $$mkcert = (Get-Command mkcert -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue); if (-not $$mkcert) { $$chocoRoot = if ($$env:ChocolateyInstall) { $$env:ChocolateyInstall } else { 'C:\\ProgramData\\chocolatey' }; $$mkcert = Join-Path $$chocoRoot 'bin\\mkcert.exe' }; if (-not (Test-Path $$mkcert)) { Write-Error 'mkcert not found. Run make mkcert-install first.'; exit 1 }; if (Test-Path '$(CERT).crt') { Write-Host 'Certificates already exist' } else { & $$mkcert -cert-file '$(CERT).crt' -key-file '$(CERT).key' '*.$(DOCKER_DOMAIN)' }"

PHONY += --certs-traefikme
--certs-traefikme: SH_CERT_FILENAME := traefik.me
--certs-traefikme: CERT := $(SH_CERTS_PATH)/$(SH_CERT_FILENAME)
--certs-traefikme:
	$(call step,Create $(SH_CERT_FILENAME) certificate in ./certs...)
	@$(PS7) "$$env:CAROOT = '$(MKCERT_CAROOT)'; $$mkcert = (Get-Command mkcert -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue); if (-not $$mkcert) { $$chocoRoot = if ($$env:ChocolateyInstall) { $$env:ChocolateyInstall } else { 'C:\\ProgramData\\chocolatey' }; $$mkcert = Join-Path $$chocoRoot 'bin\\mkcert.exe' }; if (-not (Test-Path $$mkcert)) { Write-Error 'mkcert not found. Run make mkcert-install first.'; exit 1 }; if (Test-Path '$(CERT).crt') { Write-Host 'Certificates already exist' } else { & $$mkcert -cert-file '$(CERT).crt' -key-file '$(CERT).key' '*.traefik.me' }"

PHONY += create-custom-certs
create-custom-certs: CERT := $(SH_CERTS_PATH)/$(DOMAIN)
create-custom-certs:
	$(call step,Create $(DOMAIN) certificate in ./certs...)
	@$(PS7) "$$env:CAROOT = '$(MKCERT_CAROOT)'; $$mkcert = (Get-Command mkcert -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue); if (-not $$mkcert) { $$chocoRoot = if ($$env:ChocolateyInstall) { $$env:ChocolateyInstall } else { 'C:\\ProgramData\\chocolatey' }; $$mkcert = Join-Path $$chocoRoot 'bin\\mkcert.exe' }; if (-not (Test-Path $$mkcert)) { Write-Error 'mkcert not found. Run make mkcert-install first.'; exit 1 }; if (Test-Path '$(CERT).crt') { Write-Host 'Certificates already exist' } else { & $$mkcert -cert-file '$(CERT).crt' -key-file '$(CERT).key' '*.$(DOMAIN)' }"
else
MKCERT_BIN := $(shell command -v mkcert || echo no)
MKCERT_BIN_PATH := /usr/local/bin/mkcert
MKCERT_REQS_ARCH := nss
MKCERT_REQS_DEBIAN := libnss3-tools

ifeq ($(OS_ID_LIKE),darwin)
	MKCERT_SOURCE := ${MKCERT_REPO}/releases/download/${MKCERT_VERSION}/mkcert-${MKCERT_VERSION}-darwin-$(CURRENT_ARCH)
else
	MKCERT_SOURCE := ${MKCERT_REPO}/releases/download/${MKCERT_VERSION}/mkcert-${MKCERT_VERSION}-linux-$(CURRENT_ARCH)
endif

PHONY += mkcert-install
mkcert-install: ## Install mkcert
ifeq ($(MKCERT_BIN),no)
ifeq ($(OS_ID_LIKE),darwin)
ifeq ($(BREW_BIN),no)
	$(call step,Download mkcert binary and make it executable)
	@curl -# -L ${MKCERT_SOURCE} -o ${MKCERT_BIN_PATH}
	@chmod +x ${MKCERT_BIN_PATH}
else
	$(call step,Install mkcert with brew $(MKCERT_BIN))
	@brew install mkcert
endif
else
ifeq ($(OS_ID_LIKE),debian)
	$(call step,Install mkcert requirements: $(MKCERT_REQS_DEBIAN))
	@sudo apt -y install $(MKCERT_REQS_DEBIAN)
else ifeq ($(OS_ID_LIKE),arch)
	$(call step,Install mkcert requirements: $(MKCERT_REQS_ARCH))
	@sudo pacman --noconfirm -S $(MKCERT_REQS_ARCH)
endif
	$(call step,Download mkcert binary and make it executable)
	@sudo curl -# -L ${MKCERT_SOURCE} -o ${MKCERT_BIN_PATH}
	@sudo chmod +x ${MKCERT_BIN_PATH}
endif
else
	$(call step,Install mkcert)
	$(call item,mkcert is already installed)
endif

MKCERT_CAROOT := $(PROJECT_ROOT)/certs
SH_CERTS_PATH := $(PROJECT_ROOT)/certs

PHONY += certs
certs: --certs-install-ca --certs-dockerso --certs-traefikme ## Install certs

PHONY += certs-uninstall
certs-uninstall: export CAROOT = $(MKCERT_CAROOT)
certs-uninstall: ## Uninstall certs
	$(call step,Uninstall local CA...)
	@mkcert -uninstall || echo "No CA found..."
	@rm -rf $(SH_CERTS_PATH)/*.crt $(SH_CERTS_PATH)/*.key $(SH_CERTS_PATH)/*.pem

PHONY += --certs-install-ca
--certs-install-ca: export CAROOT = $(MKCERT_CAROOT)
--certs-install-ca:
	$(call step,Create local CA...)
	@mkcert -install

PHONY += --certs-dockerso
--certs-dockerso: export CAROOT = $(MKCERT_CAROOT)
--certs-dockerso: SH_CERT_FILENAME := $(DOCKER_DOMAIN)
--certs-dockerso: CERT := $(SH_CERTS_PATH)/$(SH_CERT_FILENAME)
--certs-dockerso:
	$(call step,Create $(SH_CERT_FILENAME).crt and $(SH_CERT_FILENAME).key...)
	@test -f $(CERT).crt && echo "Certificates already exist" || \
		mkcert -cert-file $(CERT).crt -key-file $(CERT).key "*.${DOCKER_DOMAIN}"

PHONY += --certs-traefikme
--certs-traefikme: export CAROOT = $(MKCERT_CAROOT)
--certs-traefikme: SH_CERT_FILENAME := traefik.me
--certs-traefikme: CERT := $(SH_CERTS_PATH)/$(SH_CERT_FILENAME)
--certs-traefikme:
	$(call step,Create $(SH_CERT_FILENAME).crt and $(SH_CERT_FILENAME).key...)
	@test -f $(CERT).crt && echo "Certificates already exist" || \
		mkcert -cert-file $(CERT).crt -key-file $(CERT).key "*.traefik.me"

PHONY += create-custom-certs
create-custom-certs: export CAROOT = $(MKCERT_CAROOT)
create-custom-certs: CERT := $(SH_CERTS_PATH)/$(DOMAIN)
create-custom-certs:
	$(call step,Create $(DOMAIN).crt and $(DOMAIN).key...)
	@test -f $(CERT).crt && echo "Certificates already exist" || \
		mkcert -cert-file $(CERT).crt -key-file $(CERT).key "*.$(DOMAIN)"

PHONY += create-new-certs
create-new-certs: TLS_DYNAMIC_FILE := traefik/dynamic/$(DOMAIN).ssl.yml
create-new-certs:
	@$(MAKE) create-custom-certs DOMAIN=$(DOMAIN)
	$(call step,Create TLS dynamic file ./$(TLS_DYNAMIC_FILE)...)
	@printf "tls:\n  certificates:\n    - certFile: /ssl/$(DOMAIN).crt\n      keyFile: /ssl/$(DOMAIN).key\n" > $(TLS_DYNAMIC_FILE)
endif

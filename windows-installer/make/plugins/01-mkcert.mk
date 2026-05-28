MKCERT_BIN := $(shell where mkcert >NUL 2>&1 && echo yes || echo no)
MKCERT_REPO := https://github.com/FiloSottile/mkcert
MKCERT_VERSION := v1.4.4

UP_PRE_TARGETS += mkcert-install certs
POST_DOWN_ACTIONS += certs-uninstall

PHONY += mkcert-install
mkcert-install: ## Install mkcert
	$(call step,Install mkcert on Windows)
	@$(PS7) "$$mkcert = (Get-Command mkcert -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue); if (-not $$mkcert) { $$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator); if (-not $$isAdmin) { Write-Error 'Administrator terminal is required to install mkcert with Chocolatey. Re-run in elevated PowerShell: choco install mkcert -y'; exit 1 }; choco install mkcert -y | Out-Null; $$mkcert = (Get-Command mkcert -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue) }; if (-not $$mkcert) { $$chocoRoot = if ($$env:ChocolateyInstall) { $$env:ChocolateyInstall } else { 'C:\\ProgramData\\chocolatey' }; $$mkcert = Join-Path $$chocoRoot 'bin\\mkcert.exe' }; if (-not (Test-Path $$mkcert)) { Write-Error 'mkcert install failed or not found. Please run choco install mkcert -y in elevated PowerShell.'; exit 1 }; Write-Host ('mkcert ready: ' + $$mkcert)"

MKCERT_CAROOT := $(ROOT_DIR)/certs
SH_CERTS_PATH := $(ROOT_DIR)/certs

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

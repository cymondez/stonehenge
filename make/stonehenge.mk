ifndef MAKE_LIB_DIR
MAKE_LIB_DIR := $(PROJECT_ROOT)/make
endif

include $(MAKE_LIB_DIR)/os.mk

ifeq ($(OS_ID),windows)
DOCKER_BIN := $(shell where docker >NUL 2>&1 && echo yes || echo no)
CHOCO_BIN := $(shell where choco >NUL 2>&1 && echo yes || echo no)
STONEHENGE_EXISTS := $(shell docker inspect stonehenge >NUL 2>&1 && echo yes || echo no)
NETWORK_EXISTS := $(shell docker network inspect ${NETWORK_NAME} >NUL 2>&1 && echo yes || echo no)
SSH_VOLUME_EXISTS := $(shell docker volume inspect ${SSH_VOLUME_NAME} >NUL 2>&1 && echo yes || echo no)
else
ifeq ($(shell uname -m),arm64)
	CURRENT_ARCH := arm64
else ifeq ($(shell uname -m),aarch64)
	CURRENT_ARCH := arm64
else
	CURRENT_ARCH := amd64
endif
DOCKER_BIN := $(shell command -v docker || echo no)
STONEHENGE_EXISTS := $(shell docker inspect stonehenge > /dev/null 2>&1 && echo yes || echo no)
NETWORK_EXISTS := $(shell docker network inspect ${NETWORK_NAME} > /dev/null 2>&1 && echo yes || echo no)
SSH_VOLUME_EXISTS := $(shell docker volume inspect ${SSH_VOLUME_NAME} > /dev/null 2>&1 && echo yes || echo no)
endif

DOCKER_COMPOSE_CMD := docker compose
CONTAINER_NAME := stonehenge
NETWORK_NAME := $(PREFIX)-network
SSH_VOLUME_NAME := $(PREFIX)-ssh
SSH_KEYS := id_ed25519 id_rsa
ifeq ($(OS_ID),windows)
USERPROFILE_SLASH := $(subst \\,/,$(USERPROFILE))
SSH_KEY_DIR := $(USERPROFILE_SLASH)/.ssh
EXISTING_SSH_KEYS := $(foreach key,$(SSH_KEYS),$(if $(wildcard $(SSH_KEY_DIR)/$(key)),$(key),))
endif

UP_TARGETS := --up-pre-actions start --up-post-actions
UP_PRE_TARGETS := --up-title --up-create-network --up-create-volume
UP_POST_TARGETS := addkeys
DOWN_TARGETS := --down-title --remove --down-post-actions
POST_DOWN_ACTIONS := --down-remove-network --down-remove-volume

-include $(MAKE_LIB_DIR)/plugins/*.mk

PHONY += up
up: $(UP_TARGETS) ## Launch Stonehenge

PHONY += --up-pre-actions
--up-pre-actions: $(UP_PRE_TARGETS)

PHONY += --up-title
--up-title:
	$(call step,Start Stonehenge)
ifeq ($(OS_ID),windows)
	@echo Startup Stonehenge on $(OS) ($(CURRENT_ARCH))
else
	@echo "Startup Stonehenge on $(OS) ($(CURRENT_ARCH))"
endif

PHONY += --up-create-network
--up-create-network:
ifeq ($(NETWORK_EXISTS),no)
	$(call step,Create network ${NETWORK_NAME}...)
ifeq ($(OS_ID),windows)
	@docker network create ${NETWORK_NAME} >NUL 2>&1 && echo Network created || echo Network creation skipped
else
	@docker network create ${NETWORK_NAME} > /dev/null 2>&1 && echo "Network created"
endif
endif

PHONY += --up-create-volume
--up-create-volume:
ifeq ($(SSH_VOLUME_EXISTS),no)
	$(call step,Create volume ${SSH_VOLUME_NAME}...)
ifeq ($(OS_ID),windows)
	@docker volume create ${SSH_VOLUME_NAME} >NUL 2>&1 && echo Volume created || echo Volume creation skipped
else
	@docker volume create ${SSH_VOLUME_NAME} > /dev/null 2>&1 && echo "Volume created"
endif
endif

PHONY += start
start:
	$(call step,Start Stonehenge...)
	@${DOCKER_COMPOSE_CMD} up --wait --quiet-pull --force-recreate --remove-orphans

PHONY += --up-post-actions
--up-post-actions: $(UP_POST_TARGETS)
	$(call step,You can now access Stonehenge services with these URLs:)
ifdef HTTPS_PORT
	$(call item,- https://traefik.${DOCKER_DOMAIN}:$(HTTPS_PORT))
	$(call item,- https://mailpit.${DOCKER_DOMAIN}:$(HTTPS_PORT))
else
	$(call item,- https://traefik.${DOCKER_DOMAIN})
	$(call item,- https://mailpit.${DOCKER_DOMAIN})
endif
ifeq ($(OS_ID),windows)
	$(call success,SUCCESS! Happy Developing!,)
else
	$(call success,SUCCESS! Happy Developing!)
endif

PHONY += down
down: $(DOWN_TARGETS) ## Tear down Stonehenge

PHONY += --down-title
--down-title:
	$(call step,Tear down Stonehenge on $(OS))

PHONY += --remove
--remove:
	@${DOCKER_COMPOSE_CMD} down --volumes --remove-orphans --rmi all

PHONY += --down-remove-network
--down-remove-network:
	@docker network remove ${NETWORK_NAME} || docker network inspect ${NETWORK_NAME}

PHONY += --down-remove-volume
--down-remove-volume:
	@docker volume remove ${SSH_VOLUME_NAME} || docker volume inspect ${SSH_VOLUME_NAME}

PHONY += --down-post-actions
--down-post-actions: $(POST_DOWN_ACTIONS)
ifeq ($(OS_ID),windows)
	$(call success,DONE!,)
else
	$(call success,DONE!)
endif

PHONY += --addkeys-title
--addkeys-title:
	$(call step,Adding SSH keys...)

PHONY += addkeys
ifeq ($(OS_ID),windows)
addkeys: --addkeys-title $(EXISTING_SSH_KEYS)
ifeq ($(strip $(EXISTING_SSH_KEYS)),)
	@echo No SSH key found
endif
else
addkeys: --addkeys-title $(SSH_KEYS)
endif

ifeq ($(OS_ID),windows)
$(SSH_KEYS):
	@$(MAKE) addkey KEY="$(USERPROFILE)\\.ssh\\$@"

PHONY += addkey
addkey: KEY := $(USERPROFILE)\\.ssh\\id_rsa
addkey: ## Add SSH key
	@if exist "$(KEY)" (docker run --rm -it -u druid --volume="$(KEY):$(KEY)" --volumes-from=${CONTAINER_NAME} --name=${PREFIX}-ssh-agent-add-key ${STONEHENGE_IMAGE}:$(STONEHENGE_TAG) ssh-add "$(KEY)") else (echo No SSH key found)
else
$(SSH_KEYS):
	@$(MAKE) addkey KEY=$$HOME/.ssh/$@

PHONY += addkey
addkey: KEY := $(shell echo $$HOME)/.ssh/id_rsa
addkey: ## Add SSH key
	@test -f $(KEY) && docker run --rm -it -u druid \
		--volume=$(KEY):$(KEY) \
		--volumes-from=${CONTAINER_NAME} \
		--name=${PREFIX}-ssh-agent-add-key \
		${STONEHENGE_IMAGE}:$(STONEHENGE_TAG) ssh-add $(KEY) || echo "No SSH key found"
endif

PHONY += keys
keys: ## List SSH keys added
	$(call step,SSH keys added)
	@docker exec ${CONTAINER_NAME} ssh-add -l

PHONY += status
status: ## Show Stonehenge status
	$(call step,Stonehenge status)
	@${DOCKER_COMPOSE_CMD} ps --all
	@$(MAKE) keys

PHONY += ps
ps: status ## Show Stonehenge status

PHONY += stop
stop: ## Stop Stonehenge
	$(call step,Stopping Stonehenge container...)
	@${DOCKER_COMPOSE_CMD} stop

PHONY += update
update: ## Update Stonehenge
	$(call step,Pull the latest Stonehenge code...)
	@git pull
	$(call step,Pull the latest Stonehenge image...)
	@docker pull ${STONEHENGE_IMAGE}:${STONEHENGE_TAG}
	@$(MAKE) up

PHONY += upgrade
upgrade: down update ## Upgrade Stonehenge (tear down the current first)

PHONY += rollback
rollback: down ## Switch back to Stonehenge 4
	$(call step,Change to Stonehenge v4...)
ifeq ($(OS_ID),windows)
	@echo Pull the latest code...
else
	@echo "Pull the latest code..."
endif
	@git checkout 4.x && git pull
	@$(MAKE) up

include $(MAKE_LIB_DIR)/utilities.mk
include $(MAKE_LIB_DIR)/docker.mk

ifeq ($(DOCKER_BIN),no)
$(error docker is required)
endif

ifeq ($(OS_ID),windows)
ifeq ($(CHOCO_BIN),no)
$(error choco is required on Windows. Install Chocolatey first: https://chocolatey.org/install)
endif
endif

ifeq ($(DOCKER_DOMAIN),)
$(error DOCKER_DOMAIN not set in .env)
endif

ifeq ($(PREFIX),)
$(error PREFIX not set in .env)
endif

#
# Base makefile for IDEA core services
# version 3.0.6
#
# Please DO NOT CHANGE this file outside of its reference repository.
# This file may be automatically replaced.
# The reference version of this file is in the following repository:
#
#   https://gitlab-xhproject.xlab.si/IDEA/res-dev-common/services/core
#
# Any change should be submitted to the above repository.
#
# NOTE: The final Makefile has to define the following variables and targets:
#
#   * Variables:
#     - LANDSCAPE_DEV_DIR
#     - DOCKER_RUN_ARGS
#     - SERVICE_RUN_ARGS
#
#   * Targets:
#     - prepare (prepares everything needed before packaging, e.g., building)
#     - test-code
#     - test-service
#

# --- Main Docker Registry
REGISTRY ?= docker-registry.xlab.si
REGISTRY_USER ?= huawei
REGISTRY_PASS ?=

# --- Load image name and version
SERVICE=$(shell grep SERVICE MANIFEST | cut -d '=' -f2)
IMAGE_NAME=$(shell grep IMAGE MANIFEST | cut -d '=' -f2)
VERSION=$(shell grep VERSION MANIFEST | cut -d '=' -f2)

SERVICE_DEP=$(SERVICE)-dep

# --- Required Directories
LANDSCAPE_DEV_DIR ?= ../landscape-dev

# --- Extract Docker bridge and default routing interface IP addresses
DOCKER_IP=
HOST_IP=
ifneq ($(shell echo /etc/{redhat,arch}-release),)
#CENTOS or REDHAT or ARCH
	DEFAULT_INTERFACE=$(shell ip route | grep default | awk '{print $$5}')
	DOCKER_IP=$(shell ip addr | grep -A3 docker0 | grep "inet " | cut -d '/' -f 1 | sed 's/.*inet\ '//g)
	HOST_IP=$(shell ip addr | grep -A3 $(DEFAULT_INTERFACE) | grep -m 1 "inet " | cut -d '/' -f 1 | sed 's/.*inet\ '//g)
else
	ifneq ($(wildcard /etc/debian_version),)
	# Debian
		DOCKER_IP=$(shell ifconfig | grep -A3 docker0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)
		HOST_IP=$(shell route | grep default | awk '{print $$8}' | xargs ifconfig | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)
	endif
endif

ifeq ($(DOCKER_IP),)
$(warning Failed getting Docker Bridge IP address)
endif

ifeq ($(HOST_IP),)
$(warning Failed getting Host IP address)
endif

# --- Docker instances DNS setting
DNS_OPTION=--dns=$(DOCKER_IP)

# --- Capturing REMOTE vs LOCAL runs (will be removed once we have the CI in place)
TAG_LOCAL=local
TAG_REMOTE=$(VERSION)

CONFIG=
REMOTE ?= no
PUSH_VERSION_CHECK ?= yes

ifeq "$(REMOTE)" "yes"
	PUSH_CONFIRM=$(CONFIRM)
	TAG=$(TAG_REMOTE)
	FULL_IMAGE_NAME=$(REGISTRY)/$(IMAGE_NAME)
else
	PUSH_CONFIRM=no
	TAG=$(TAG_LOCAL)
	FULL_IMAGE_NAME=$(IMAGE_NAME)
endif


# --- Common Targets

# make sure test, build, and clean do not refer to files or folders
.PHONY: destroy test build clean

# make sure the targets are executed sequentially
.NOTPARALLEL:

# report the current settings
report:
	@echo Image Name: $(IMAGE_NAME)
	@echo Version: $(VERSION)
	@echo Docker IP: $(DOCKER_IP)
	@echo HOST_IP: $(HOST_IP)


# starts an instance of the service docker image
start: destroy
ifdef CONFIG
	docker run -d --name $(SERVICE) $(DNS_OPTION) $(DOCKER_RUN_ARGS) -e "IDEA_SERVICE_CONFIG=`cat $(CONFIG) | tr '\n' ' '`" $(IMAGE_NAME):$(TAG) $(SERVICE_RUN_ARGS) >> .containers.tmp
else
	docker run -d --name $(SERVICE) $(DNS_OPTION) $(DOCKER_RUN_ARGS) $(IMAGE_NAME):$(TAG) $(SERVICE_RUN_ARGS) >> .containers.tmp
endif
	sleep 5

restart:
	for container in `cat .containers.tmp || ""`; do if [ -n $$container ]; then docker restart -t 1 $$container; fi; done

# stop instances
stop:
	docker ps -a  --filter name=$(SERVICE) | grep "$(SERVICE)$$" | awk '{print $$1}' | xargs -r echo | xargs -r docker stop

# stop and remove instances
destroy: stop
	docker ps -a  --filter name=$(SERVICE) | grep "$(SERVICE)$$" | awk '{print $$1}' | xargs -r echo | xargs -r docker rm -v
	rm -f .containers.tmp

# builds a docker image
package: destroy prepare
	docker build --pull --force-rm=true --tag $(IMAGE_NAME):$(TAG) $(DOCKER_BUILD_ARGS) .

landscape-dep: | $(wildcard $(LANDSCAPE_DEV_DIR))
	if [ -n "$|" ];then cd $| && $(MAKE) destroy; fi
	if [ -n "$|" ];then cd $| && $(MAKE) $(SERVICE_DEP); fi

landscape-destroy: | $(wildcard $(LANDSCAPE_DEV_DIR))
	if [ -n "$|" ];then cd $| && $(MAKE) destroy; fi

test: landscape-dep test-code test-service
	$(MAKE) destroy
	$(MAKE) landscape-destroy

push:
ifeq "$(PUSH_CONFIRM)" "yes"

ifeq "$(PUSH_VERSION_CHECK)" "yes"
	@curl --fail -ks -H "Authorization: Basic `echo -n $(REGISTRY_USER):$(REGISTRY_PASS) |base64`" https://$(REGISTRY)/v2/_catalog > /dev/null 2>&1 || (echo "ERROR: Failed to connect to the registry!"; exit 1)
	@curl -ks -H "Authorization: Basic `echo -n $(REGISTRY_USER):$(REGISTRY_PASS) |base64`" https://$(REGISTRY)/v2/$(IMAGE_NAME)/tags/list \
		| grep -v "$(TAG)" \
		|| (echo "ERROR: Image version $(TAG) already exists in the repository! Please increase version number in the MANIFEST file."; exit 1)
endif
	docker tag $(IMAGE_NAME)\:$(TAG) $(FULL_IMAGE_NAME)\:$(TAG)
	docker push $(FULL_IMAGE_NAME)\:$(TAG)
	docker tag $(IMAGE_NAME)\:$(TAG) $(FULL_IMAGE_NAME)\:latest
	docker push $(FULL_IMAGE_NAME)\:latest
else
	@echo
	@echo "!! SKIPPED. Use 'make push REMOTE=yes CONFIRM=yes'."
endif

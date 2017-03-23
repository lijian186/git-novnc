#
# Makefile for idea webcommit microtool
#

include ./scripts/base.mk
include ./scripts/nodes.mk

LANDSCAPE_DEV_DIR=../landscape-dev

DOCKER_RUN_ARGS=-v $(CURDIR):/service:rw -v /service/node_modules
SERVICE_RUN_ARGS=
package:
	docker build -t ${REGISTRY}/${IMAGE}:latest .

test-code:
	@echo No code test available.

test-service: start
	@echo No code test available.

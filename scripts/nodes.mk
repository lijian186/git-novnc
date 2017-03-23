#
# Common Makefile targets for NodeJS core services
# version 1.2.0
#
# Please DO NOT CHANGE this file outside of its reference repository.
# This file may be automatically replaced.
# The reference version of this file is in the following repository:
#
#   https://gitlab-xhproject.xlab.si/IDEA/res-dev-common/services/core
#
# Any change should be submitted to the above repository.
#

node-clean:
	rm -rf node_modules

node-install: node-clean
	npm install

# runs the code in a local process
node-run:
	set -o pipefail; npm start -s | ./node_modules/.bin/bunyan

prepare:
	@echo Nothing to prepare.

#!/usr/bin/env sh

# Wrapper script for build_platform_images.js
#
# This script is intended to be called by a corresponding script for a specific application
#
# eg.
#
# node_modules/\@ministryofjustice/fb-deploy-utils/bin/build_platform_images.sh $@ --app fb-service-token-cache
#
# node_modules/\@ministryofjustice/fb-deploy-utils/bin/build_platform_images.sh $@ --app fb-publisher --images base --images web --images worker

node $(dirname $0)/build_platform_images.js $@

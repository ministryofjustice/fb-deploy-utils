#!/usr/bin/env node

const { buildPush } = require('@ministryofjustice/fb-deploy-utils')

const args = require('yargs').argv

buildPush(args.app, args.images)

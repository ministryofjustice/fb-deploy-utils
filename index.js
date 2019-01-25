const buildPush = require('./lib/build_push')
const repoSecrets = require('./lib/repo_secrets')

module.exports = Object.assign({}, repoSecrets, {
  buildPush
})

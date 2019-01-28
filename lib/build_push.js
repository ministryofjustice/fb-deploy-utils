const execSync = require('child_process').execSync
const {getAppRepoSecrets} = require('./repo_secrets')

/**
 * Build platform-specific application container image[s] and push to ECR
 *
 * @param {string} name
 * Application name
 *
 * @param {array} [images]
 * Image suffixes
 * eg. base, api, worker
 *
 * @return {undefined}
 *
 **/
const buildPush = (name, images) => {
  const argv = require('yargs')
    .help()
    .usage('\n$0 -p <platform>')
    .option('platform', {
      alias: 'p',
      demandOption: true,
      describe: 'Platform environment to build for',
      type: 'string',
      choices: [
        'test',
        'integration',
        'live'
      ]
    })
    .argv

  const appSecrets = getAppRepoSecrets(name, images)
  execSync(`${appSecrets} make ${argv.platform} build_and_push`, {stdio: 'inherit'})
}

module.exports = buildPush

const execSync = require('child_process').execSync
const { getAppRepoSecrets } = require('./repo_secrets')

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
  const config = require('yargs')
    .help()
    .usage('\n$0 -p <platform>')
    .option('platform', {
      alias: 'p',
      describe: 'Platform environment to build for',
      type: 'string',
      choices: [
        'test',
        'integration',
        'live'
      ],
      conflicts: 'target'
    })
    .option('target', {
      alias: 't',
      describe: 'Target platform to build for',
      type: 'string',
      conflicts: 'platform',
      hidden: true
    })

  const argv = config.argv
  if (argv.h) {
    config.getUsageInstance().showHelp()
    process.exit()
  }

  if (argv.target) {
    argv.platform = 'target'
  }

  if (!argv.platform) {
    config.getUsageInstance().showHelp()
    process.stdout.write(`
    Invalid values:
        Argument: platform, Choices: "test", "integration", "live"`)
    process.exit(1)
  }

  const appSecrets = getAppRepoSecrets(name, images)

  try {
    execSync(`${appSecrets} ${argv.target ? `TARGET=${argv.target}` : ''} make ${argv.platform} build_and_push`, { stdio: 'inherit' })
  } catch {
    console.log(`Failed: make ${argv.platform} build_and_push`)
    process.exit(1)
  }
}

module.exports = buildPush

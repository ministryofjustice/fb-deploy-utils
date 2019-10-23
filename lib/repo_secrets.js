const execSync = require('child_process').execSync

/**
 * Decode base64-encoded string
 *
 * @param {string} b64string
 * String to decode
 *
 * @return {string}
 * Decoded string
 *
 **/
const decodeStr = (b64string) => Buffer.from(b64string, 'base64').toString()

/**
 * Return secrets for an ECR repo
 *
 * @param {string} app
 * Application name
 *
 * @param {string} [image=default]
 * Image suffix
 * Ignored if 'default'
 *
 * @param {boolean} [decode=true]
 * Whether to decode secrets
 * Defaults to true
 *
 * @return {object}
 * Object containing access_key_id, secret_access_key and repo_url properties
 *
 **/
const getImageRepoSecrets = (app, image = 'default', decode = true) => {
  image = image !== 'default' ? `-${image}` : ''
  const secret = execSync(`kubectl get secrets -n formbuilder-repos ecr-repo-${app}${image} -o json`)
  const jsonString = secret.toString()
  const jsonConfig = JSON.parse(jsonString)
  const jsonData = jsonConfig.data
  if (decode) {
    Object.keys(jsonData).forEach(key => {
      jsonData[key] = decodeStr(jsonData[key])
    })
  }
  return jsonData
}

/**
 * Return string  platform-specific application container image[s] and push to ECR
 *
 * @param {string} name
 * Application name
 *
 * @param {array} [images]
 * Image suffixes
 * eg. base, api, worker
 *
 * @return {string}
 *
 *
 **/
const getAppRepoSecrets = (name, images) => {
  images = images || ['default']
  const secrets = {}
  images.forEach(image => {
    secrets[image] = getImageRepoSecrets(name, image)
  })

  let envString = ''
  Object.keys(secrets).forEach(image => {
    const secret = secrets[image]
    const suffix = image !== 'default' ? `_${image.toUpperCase()}` : ''
    envString += `AWS_ACCESS_KEY_ID${suffix}="${secret.access_key_id}" `
    envString += `AWS_SECRET_ACCESS_KEY${suffix}="${secret.secret_access_key}" `
  })
  return envString
}

module.exports = {
  getImageRepoSecrets,
  getAppRepoSecrets
}

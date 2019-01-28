# fb-deploy-utils

Utility scripts to aid deployment of Form Builder platform applications

## Install

```bash
npm install @ministryofjustice/fb-deploy-utils --save-dev
```

## Scripts

The following helper scripts are available
`node_modules/@ministryofjustice/fb-deploy-utils/bin`

They are intended to be called by corresponding scripts for a specific application

`build_platform_images.sh`

Builds all images for the application, retrieves the AWS secrets for each image repo, and pushes the images to the ECR repo

`deploy_platform.sh`

Generates kubernetes config files from and applies to the 

`restart_platform_pods.sh`

Deletes application pods which Kubernetes will then recreate as specified by the application's deployment 


All script args and options can viewed by passing the `-h` option

All scripts take the `-p` parameter to specify the platform environment

All scripts take the `-n` parameter to perform a dry run
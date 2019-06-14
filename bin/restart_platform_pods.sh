#!/usr/bin/env bash

# This script is intended to be called by a corresponding script for a specific application
# with the application passed in as an environment variable, FB_APPLICATION
#
# eg.
#
# FB_APPLICATION='fb-service-token-cache' node_modules/\@ministryofjustice/fb-deploy-utils/bin/restart_platform_pods.sh $@

if [ "$FB_APPLICATION" = "" ]; then
  echo "
FB_APPLICATION must be set

  "
  exit 1
fi

if [ "$FB_NAMESPACE" = "" ]; then
  FB_NAMESPACE='platform'
fi

HERE=$0

usage () {
  if [ "$FB_DEPLOYMENT_ENV" != "none" ]; then
    DEPLOYMENT_ENV_EXAMPLE="[-d deployment] "
    DEPLOYMENT_ENV_USAGE="
  -d, --deployment (optional)

    dev|staging|production

    Deployment environment to restart pods in
    If not specified, defaults to all environments
  "
  fi
  echo "
USAGE

  restart_platform_pods.sh -p platform $DEPLOYMENT_ENV_EXAMPLE[-c context] [-nh]

PARAMETERS

  -p, --platform

    test|integration|live

    Platform environment to restart pods in
  $DEPLOYMENT_ENV_USAGE
  -c, --context (optional)

    Kubernetes context to run commands in

    If not specified, defaults to context from kube config

    Can also be passed as an environment variable, FB_CONTEXT

FLAGS

  -n, --dry-run        show commands that would be run
  -h, --help           help
"

  EXIT_CODE=$1
  [ "$EXIT_CODE" = "" ] && EXIT_CODE=0
  exit $EXIT_CODE
}

DEPLOYMENT_ENVS=($FB_DEPLOYMENT_ENV)

while [ "$1" != "" ]; do
    INPUT=$1
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | sed 's/^[^=]*=//g'`
    shift
    if [ "$VALUE" = "$PARAM" ]; then
      VALUE=""
    fi
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -p | --platform)
            if [ "$VALUE" = "" ]; then
              VALUE=$1
              shift
            fi
            PLATFORM_ENV=$VALUE
            ;;
        -d | --deployment)
            if [ "$FB_DEPLOYMENT_ENV" = "none" ]; then
              echo "
--deployment option not allowed
            "
              usage 1
            fi
            if [ "$VALUE" = "" ]; then
              VALUE=$1
              shift
            fi
            DEP_LENGTH=${#DEPLOYMENT_ENVS[@]}
            DEPLOYMENT_ENVS[$DEP_LENGTH]=$VALUE
            ;;
        -c | --context)
            if [ "$VALUE" = "" ]; then
              VALUE=$1
              shift
            fi
            FB_CONTEXT=($VALUE)
            ;;
        -n | --dry-run)
            DRY_RUN=true
            ;;
        *)
            echo "Unknown parameter \"$PARAM\""
            # usage 1
            ;;
    esac
done

if [ "$PLATFORM_ENV" = "" ]; then
  echo "
--platform must be set

  "
  usage 1
fi

DEP_LENGTH=${#DEPLOYMENT_ENVS[@]}
if [ "$DEP_LENGTH" = "0" ]; then
  DEPLOYMENT_ENVS=("dev" "staging" "production")
fi

for DEPLOYMENT_ENV in ${DEPLOYMENT_ENVS[*]};
do
  if [ "$DEPLOYMENT_ENV" = "none" ]; then
    ENV=$PLATFORM_ENV
  else
    ENV=$PLATFORM_ENV-$DEPLOYMENT_ENV
  fi
  
  ENVCMD="kubectl delete pods -l appGroup=$FB_APPLICATION --context=$FB_CONTEXT --namespace=formbuilder-$FB_NAMESPACE-$ENV"

  echo "$ENVCMD"
  if [ "$DRY_RUN" = "true" ]; then
    echo "Skipping restart"
  else
    $ENVCMD
  fi
  
done

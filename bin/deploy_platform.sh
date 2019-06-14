#!/usr/bin/env bash

# This script is intended to be called by a corresponding script for a specific application
# with the application passed in as an environment variable, FB_APPLICATION
#
# eg.
#
# FB_APPLICATION='fb-service-token-cache' node_modules/\@ministryofjustice/fb-deploy-utils/bin/deploy_platform.sh $@

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

    Deployment environment to deploy to
    If not specified, defaults to all environments
  "
  fi
  echo "
USAGE

  deploy_platform.sh -p platform $DEPLOYMENT_ENV_EXAMPLE[-c context] [-nh]

PARAMETERS

  -p, --platform

    test|integration|live

    Platform environment to deploy to
  $DEPLOYMENT_ENV_USAGE
  -r, --deployment-repo (optional)

    Path to deployment repo
    If not specified, defaults to the assumption that $FB_APPLICATION-deploy is in the same directory as $FB_APPLICATION

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
        -r | --deployment-repo)
            if [ "$VALUE" = "" ]; then
              VALUE=$1
              shift
            fi
            DEPLOYMENT_REPO=$VALUE
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

if [ "$DEPLOYMENT_REPO" = "" ]; then
  CHANGEPATH=$(dirname "$HERE")
  CHANGEPATH="$CHANGEPATH/../../../../../$FB_APPLICATION-deploy"
  DEPLOYMENT_REPO=$( cd "$CHANGEPATH" ; pwd -P )
fi

if [ ! -d "$DEPLOYMENT_REPO" ]; then
  echo "
No deployment repo found at $DEPLOYMENT_REPO

  "
  usage 2
fi

CHARTNAME="$FB_APPLICATION-chart"

for DEPLOYMENT_ENV in ${DEPLOYMENT_ENVS[*]};
do
  if [ "$DEPLOYMENT_ENV" = "none" ]; then
    ENV=$PLATFORM_ENV
  else
    ENV=$PLATFORM_ENV-$DEPLOYMENT_ENV
  fi

  CONFIG_FILE="/tmp/$FB_APPLICATION-$ENV.yaml"

  HELMCMD=''

  ValuesConfig="$DEPLOYMENT_REPO/values/$ENV-values.yaml"
  [ -f "$ValuesConfig" ] && HELMCMD="$HELMCMD -f $ValuesConfig"

  SharedSecretsConfig="$DEPLOYMENT_REPO/secrets/shared-secrets-values.yaml"
  [ -f "$SharedSecretsConfig" ] && HELMCMD="$HELMCMD -f $SharedSecretsConfig"

  SecretsConfig="$DEPLOYMENT_REPO/secrets/$ENV-secrets-values.yaml"
  [ -f "$SecretsConfig" ] && HELMCMD="$HELMCMD -f $SecretsConfig"

  HELMCMD="helm template deploy/$CHARTNAME $HELMCMD --set environmentName=$ENV --set platformEnv=$PLATFORM_ENV"

  echo $HELMCMD
  echo "Writing $ENV config to $CONFIG_FILE"
  $HELMCMD > $CONFIG_FILE

  if [ "$DRY_RUN" = "true" ]; then
    echo "Skipping kubectl apply"
  else
    KUBECTLCMD="kubectl apply -f $CONFIG_FILE"
    if [ "$FB_APPLY_NAMESPACE" != "false" ]; then
      KUBECTLCMD="$KUBECTLCMD -n formbuilder-$FB_NAMESPACE-$ENV"
    fi
    echo $KUBECTLCMD
    $KUBECTLCMD
  fi
  
done

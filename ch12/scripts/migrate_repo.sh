#!/bin/bash

GITEA_FQDN=${1}
GITEA_HOST=${GITEA_FQDN:=git.upandrunning.local}
GITEA_SCHEME=${GITEA_SCHEME:=https}
GITEA_URL=${GITEA_SCHEME}://${GITEA_HOST}

# Based on the helm chart
GITEA_USERNAME="gitea_admin"
GITEA_PASSWORD="Argocdupandrunning1234@"

orgName=upandrunning

if [[ -z $GITEA_USERNAME ]] || [[ -z $GITEA_PASSWORD ]]; then
    echo "GITEA_USERNAME or GITEA_PASSWORD variables are not defined"
    exit 1
fi

function migrateRepository() {

  local repoName=$1
  local private=$2
  local remoteURL=$3

    repo_create_http_code=$(curl -s -o /dev/null -w ''%{http_code}'' -L -k -X POST  "$GITEA_URL/api/v1/repos/migrate" -u $GITEA_USERNAME:$GITEA_PASSWORD -H  "accept: application/json" -H  "Content-Type: application/json" -d "{ \
  \"clone_addr\": \"${remoteURL}\", \
  \"repo_owner\": \"${orgName}\",
  \"repo_name\": \"${repoName}\", \
  \"private\": ${private} }")

    if [ "$repo_create_http_code" != "201" ]; then

      echo "Failed to create \"$repoName\" Repository..."
      exit 1 
    else
      echo "Migrating \"$remoteURL\" into \"$repoName\" ..."
    fi
}

migrateRepository "simple-go" false "https://github.com/christianh814/simple-go-deployment"

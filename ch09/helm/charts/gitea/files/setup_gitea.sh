#!/bin/bash

GITEA_HOST=${GITEA_HOST:=gitea}
GITEA_PORT=${GITEA_PORT:=3000}
GITEA_SCHEME=${GITEA_SCHEME:=http}
GITEA_URL=${GITEA_SCHEME}://${GITEA_HOST}:${GITEA_PORT}

orgName=upandrunning

if [[ -z $GITEA_USERNAME ]] || [[ -z $GITEA_PASSWORD ]]; then
    echo "GITEA_USERNAME or GITEA_PASSWORD variables are not defined"
    exit 1
fi

function createRepository() {

  local repoName=$1
  local private=$2
  local displayName=$3

  # Create Repository
  if [[ "$(curl -L -s --insecure -o /dev/null -w ''%{http_code}'' -u $GITEA_USERNAME:$GITEA_PASSWORD ${GITEA_URL}/api/v1/repos/${orgName}/${repoName})" == "404" ]]; then

    echo "Creating Repository \"${repoName}\""

    repo_create_http_code=$(curl -s -o /dev/null -w ''%{http_code}'' -L -k -X POST  "$GITEA_URL/api/v1/orgs/${orgName}/repos" -u $GITEA_USERNAME:$GITEA_PASSWORD -H  "accept: application/json" -H  "Content-Type: application/json" -d "{  \
        \"name\": \"${repoName}\", \
        \"auto_init\": true, \
        \"private\": ${private}}")

    if [ "$repo_create_http_code" != "201" ]; then

      echo "Failed to create \"$repoName\" Repository..."
      exit 1 
    fi

  fi

  # Create file in repository
  if [[ "$(curl -L -s --insecure -o /dev/null -w ''%{http_code}'' -u $GITEA_USERNAME:$GITEA_PASSWORD ${GITEA_URL}/api/v1/repos/${orgName}/${repoName}/contents/manifests/configmap.yaml)" == "404" ]]; then

filecontents=$(base64 <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${repoName}
data:
  content: Chapter 9 - Security - ${displayName}
EOF
)

    # Add File to Repository
    file_create_http_code=$(curl -s -o /dev/null -w ''%{http_code}'' -L -k -X POST  "$GITEA_URL/api/v1/repos/${orgName}/${repoName}/contents/manifests/configmap.yaml" -u $GITEA_USERNAME:$GITEA_PASSWORD -H  "accept: application/json" -H  "Content-Type: application/json" -d "{  \
        \"content\": \"$filecontents\"}")
    
    if [ "$file_create_http_code" != "201" ]; then

      echo "Failed to create ConfigMap file in \"$repoName\" Repository..."
      exit 1 
    fi

  fi

}

echo "Waiting for Gitea to become available..."
while [[ "$(curl -L -s --insecure -o /dev/null -w ''%{http_code}'' ${GITEA_URL}/api/healthz)" != "200" ]]; do sleep 5; done

echo "Waiting for User to be created..."
while [[ "$(curl -L -s --insecure -o /dev/null -w ''%{http_code}'' -u $GITEA_USERNAME:$GITEA_PASSWORD ${GITEA_URL}/api/v1/user)" != "200" ]]; do sleep 5; done


if [[ "$(curl -L -s --insecure -o /dev/null -w ''%{http_code}'' -u $GITEA_USERNAME:$GITEA_PASSWORD ${GITEA_URL}/api/v1/orgs/${orgName})" == "404" ]]; then
  # Creating a Organization
  echo "Creating \"$orgName\" Organization..."
  org_create_http_code=$(curl -s -o /dev/null -w ''%{http_code}'' -L -k -X POST "$GITEA_URL/api/v1/orgs" -u $GITEA_USERNAME:$GITEA_PASSWORD -H  "accept: application/json" -H  "Content-Type: application/json" -d "{  \
      \"full_name\": \"Argo CD Up and Running\", \
      \"repo_admin_change_team_access\": true, \
      \"visibility\": \"public\", \
      \"username\": \"${orgName}\"}")
    
  if [ "$org_create_http_code" != "201" ]; then

    echo "Failed to create \"$orgName\" Organization"
    exit 1 
  fi

fi

createRepository "ch09-tls" false "TLS"
createRepository "ch09-credentials-https" true "HTTPS Credentials"
createRepository "ch09-credentials-ssh" true "SSH Credentials"
createRepository "ch09-gpg-signatures" false "GPG Signatures"

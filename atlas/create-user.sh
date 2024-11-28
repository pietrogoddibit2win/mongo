#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source $SCRIPT_DIR/.env

# Generate an access token
ACCESS_TOKEN=$(curl --request POST \
  --url "https://cloud.mongodb.com/api/atlas/v1.0/oauth/token" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET" | jq -r '.access_token')
AUTHORIZATION=Bearer $ACCESS_TOKEN

echo "$AUTHORIZATION"

# List all projects
PROJECTS=$(curl --request GET \
  --url "https://cloud.mongodb.com/api/atlas/v1.0/groups" \
  --header "Authorization: $AUTHORIZATION" \
  --header "Accept: application/json")

# Find the project ID by project name
ERROR=$(echo $PROJECTS | jq -r '.error')
if [ "$ERROR" = "401" ]; then
  echo "unauthorized"
  exit 0
fi

# Find the project ID by project name
PROJECT_ID=$(echo $PROJECTS | jq -r --arg PROJECT_NAME "$PROJECT_NAME" '.results[] | select(.name == $PROJECT_NAME) | .id')
if [ -n "$PROJECT_ID" ]; then
  echo "Project $PROJECT_NAME found with id $PROJECT_ID"

  # # Make the API request to retrieve cluster information
  # curl -s -X GET \
  #   --header "Authorization: Basic ${ENCODED_CREDS}" \
  #   --header "Content-Type: application/json" \
  #   "https://cloud.mongodb.com/api/atlas/v1.0/groups/${PROJECT_ID}/clusters/${CLUSTER_NAME}"

  # Make the API request to create a new database user
  NAMESPACE=test-script
  NEW_USERNAME=user-$NAMESPACE
  NEW_PASSWORD=$NEW_USERNAME
  NEW_DATABASE=$NAMESPACE-db

  # Create a database user
  curl --request POST \
    --url "https://cloud.mongodb.com/api/atlas/v1.0/groups/$GROUP_ID/databaseUsers" \
    --header "Authorization: Bearer $ACCESS_TOKEN" \
    --header "Content-Type: application/json" \
    --data '{
    "databaseName": "admin",
    "roles": [
      {
           "databaseName":  "'"$NEW_DATABASE"'",
           "roleName": "readWrite"
         }
    ],
    "username": "'"$USERNAME"'",
    "password": "'"$PASSWORD"'"
  }'

else
  echo "Project with name '$PROJECT_NAME' not found."
fi

#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source $SCRIPT_DIR/.env

# Make the API call to list all projects
PROJECTS=$(curl --user "$PUBLIC_KEY:$PRIVATE_KEY" --digest \
  --header "Content-Type: application/json" \
  --header "Accept: application/vnd.atlas.2024-08-05+json" \
  --silent \
  --request GET "https://cloud.mongodb.com/api/atlas/v2/groups")
# Filter the response to find the project by name
PROJECT_ID=$(echo "$PROJECTS" | jq -r --arg name "$PROJECT_NAME" '.results[] | select(.name == $name) | .id')

echo "PROJECT_ID: $PROJECT_ID"
if [ -n "$PROJECT_ID" ]; then
  echo "Project $PROJECT_NAME found with id $PROJECT_ID"

  # # Make the API request to retrieve cluster information
  # CLUSTERS=$(curl --user "$PUBLIC_KEY:$PRIVATE_KEY" --digest \
  #   --header "Content-Type: application/json" \
  #   --header "Accept: application/vnd.atlas.2024-08-05+json" \
  #   --silent \
  #   --request GET "https://cloud.mongodb.com/api/atlas/v2/groups/${PROJECT_ID}/clusters/${CLUSTER_NAME}")

  # Make the API request to create a new database user
  NAMESPACE=test-script
  NEW_USERNAME=user-$NAMESPACE
  NEW_PASSWORD=$NEW_USERNAME
  NEW_DATABASE=$NAMESPACE-db

  curl --user "$PUBLIC_KEY:$PRIVATE_KEY" --digest \
    --request POST --url "https://cloud.mongodb.com/api/atlas/v2/groups/${PROJECT_ID}/databaseUsers" \
    --header "Content-Type: application/json" \
    --header "Accept: application/vnd.atlas.2024-08-05+json" \
    --data '{
       "databaseName": "admin",
       "roles": [
         {
           "databaseName":  "'"$NEW_DATABASE"'",
           "roleName": "readWrite"
         }
       ],
       "username": "'"$NEW_USERNAME"'",
       "password": "'"$NEW_PASSWORD"'"
     }'
else
  echo "Project with name '$PROJECT_NAME' not found."
fi

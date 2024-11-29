#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source $SCRIPT_DIR/.env

############ VARIABLES ############
# export SECRET_MONGO_NAME="secret-mongo"
# # activate service account
# gcloud auth activate-service-account --key-file=/secrets/credentials.json
# # retrieve mongo secret from GCP secret manager
# secret_mongo=$(read_secret $SECRET_MONGO_NAME)
# echo "GCLOUD: reading secret '$SECRET_MONGO_NAME'"
# if [[ "$secret_mongo" == "" ]]; then
#   echo "GCLOUD: '$SECRET_MONGO_NAME' secret does not exists"
#   exit 1
# fi

# # get variables from input defining env var to be used in script
# export PROJECT_NAME="{{ inputs.mongo_project }}"
# export CLUSTER_NAME="{{ inputs.mongo_cluster }}"
# export NAMESPACE="{{ inputs.namespace }}"
# export NEW_USERNAME="{{ inputs._username }}"
# export NEW_USERNAME_READ_ONLY="{{ inputs._username_ro }}"
# # retrieve private and public key used in mongo api
# export PRIVATE_KEY=$(echo "$secret_mongo" | jq -r '.default.private_api_key')
# export PUBLIC_KEY=$(echo "$secret_mongo" | jq -r '.default.public_api_key')

######################## just for local test
export NEW_USERNAME="user-$NAMESPACE"
export NEW_USERNAME_READ_ONLY="user-$NAMESPACE-ro"
######################## just for local test

###### FUNCTIONS ######
# Function to perform a dynamic curl request and return response body and status code
curl_request() {
  local method=$1
  local url=$2
  local data=$3
  # Perform the curl request based on the data
  if [ -n "$data" ]; then
    response=$(
      curl --user "$PUBLIC_KEY:$PRIVATE_KEY" --digest \
        --silent \
        --write-out "%{http_code}" \
        --header "Content-Type: application/json" \
        --header "Accept: application/vnd.atlas.2024-08-05+json" \
        --request $method "$url" \
        --data "${request_body}"
    )
  else
    response=$(
      curl --user "$PUBLIC_KEY:$PRIVATE_KEY" --digest \
        --silent \
        --write-out "%{http_code}" \
        --header "Content-Type: application/json" \
        --header "Accept: application/vnd.atlas.2024-08-05+json" \
        --request $method "$url"
    )
  fi
  # The last three characters (${response_body: -3}) are assigned to http_code.
  http_code="${response: -3}"
  # The remaining part (${response_body%???}) contains the response body.
  response_body="${response%???}"

  # Return HTTP status code and response body
  echo "$http_code"
  echo "$response_body"
}
# Function to check if the status code is within the acceptable range
check_status_code() {
  local http_code=$1
  local response_body=$2
  local skip_exit=$3
  if [[ "$http_code" =~ ^2[0-9]{2}$ ]]; then
    echo "Success: HTTP $http_code"
  else
    echo "Error: HTTP $http_code"
    echo "Error: Response $response_body"
    if [ "$skip_exit" != "true" ]; then
      echo "Error: EXIT"
      exit 1 # Exit if error
    fi
  fi
}
# cretae user on mongo and create GCP secret
delete_user() {
  local username=$1
  user_response=$(curl_request "DELETE" "https://cloud.mongodb.com/api/atlas/v2/groups/${PROJECT_ID}/databaseUsers/admin/${username}")
  # Check the status code and exit on failure
  http_code=$(echo "$user_response" | head -n 1)
  # Capture the body from the function output
  USERS=$(echo "$user_response" | tail -n +2)
  check_status_code "$http_code" "$USERS" "true"

  # secret_user_name="$SECRET_MONGO_NAME-$database"
  # secret_user=$(read_secret $secret_user_name)
  # if [ -n "$secret_user" ]; then
  #   echo "deleting secret '$secret_user_name'"
  #   gcloud secrets delete $secret_user_name --project={{ inputs.master_project }} --quiet
  # fi
}

############ EXECUTION ############
# retrive projects
projects_response=$(curl_request "GET" "https://cloud.mongodb.com/api/atlas/v2/groups")
# Capture the status code and body from the function output
http_code=$(echo "$projects_response" | head -n 1)
# Capture the body from the function output
projects=$(echo "$projects_response" | tail -n +2)
# Check the status code and exit on failure
check_status_code "$http_code" "$projects"

# Filter the response to find the project by name
project=$(echo "$projects" | jq -r --arg project_name "$PROJECT_NAME" '.results[] | select(.name == $project_name)')
# Filter the response to find the project by name
export PROJECT_ID=$(echo "$project" | jq -r '.id')
if [ -n "$PROJECT_ID" ]; then
  echo "Project $PROJECT_NAME found with id $PROJECT_ID"

  ############ USER ############
  new_username=$NEW_USERNAME
  delete_user "$new_username"
  ############ READ ONLY USER ############
  new_username_read_only=$NEW_USERNAME_READ_ONLY
  delete_user "$new_username_read_only"
else
  echo "project with name '$PROJECT_NAME' does not exists!"
fi

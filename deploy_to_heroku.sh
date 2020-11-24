#!/bin/bash 
set -euo pipefail

# Remove any paths if currently present for clean workdir.
rm -rf ./bitwarden_rs
rm -rf ./scripts-common
rm -rf ./.git

git init

REPO_FOLDER="bitwarden_rs"

echo "Clone scripts-common for utilities; init and update."
git submodule add -b stable https://gitlab.com/bertrand-benoit/scripts-common.git
git submodule init && git submodule update

currentDir=$( dirname "$( command -v "$0" )" )
scriptsCommonUtilities="$currentDir/scripts-common/utilities.sh"
[ ! -f "$scriptsCommonUtilities" ] && echo -e "ERROR: scripts-common utilities not found, you must initialize your git submodule once after you cloned the repository:\ngit submodule init\ngit submodule update" >&2 && exit 1
# shellcheck disable=1090
. "$scriptsCommonUtilities"

echo "Clone current bitwarden_rs with depth 1"
git clone --depth 1 https://github.com/dani-garcia/bitwarden_rs.git

checkPath "$REPO_FOLDER" || errorMessage "Path '$REPO_FOLDER' should exist. Check if the git clone functioning."
checkBin heroku || errorMessage "This tool requires heroku CLI to be installed. Install it please, and then run this tool again after cleaning the folder."
checkBin jq || errorMessage "This tool requires jq to be installed. Install it please, and then run this tool again after cleaning the folder."
checkBin openssl || errorMessage "This tool requires openssl to be installed. Install it please, and then run this tool again after cleaning the folder."
checkBin docker || errorMessage "This tool requires Docker, required for building the image, to be installed. Install it please, and then run this tool again after cleaning the folder."

echo "Heroku uses random ports for assignment with httpd services. We are modifying the ROCKET_PORT for startup."
sed -i '2 a export ROCKET_PORT=$PORT\n' ./bitwarden_rs/docker/start.sh

echo "Make sure we are logged into Heroku first!"
ARE_WE_LOGGED_IN=$(heroku auth:whoami)

if [[ "$ARE_WE_LOGGED_IN" != *"Error"* ]]; then
  echo "We are logged in! Continuing."
else
  echo "You are not logged in. Please login to Heroku first."
  exit 1
fi

echo "Logging into Heroku Container Registry to push the image (this will add an entry in your Docker config)"
heroku container:login

echo "We must create an application to deploy first"
APP_NAME=$(heroku create --json | jq --raw-output '.name')

echo "We will use JawsDB Maria edition, which is free and sufficient for a small instance"
heroku addons:create jawsdb -a $APP_NAME

echo "Now we use the JAWS DB config as the database URL"
heroku config:set DATABASE_URL=$(heroku config:get JAWSDB_URL -a $APP_NAME) -a $APP_NAME

echo "Additionally set an Admin Token too"
heroku config:set ADMIN_TOKEN=$(openssl rand -base64 48) -a $APP_NAME

echo "And set DB connections to five in order not to saturate the free DB"
heroku config:set DATABASE_MAX_CONNS=5 -a $APP_NAME

echo "Now we will build the amd64 image to deploy to Heroku with the specified port changes"
mv ./${REPO_FOLDER}/docker/amd64/Dockerfile ./${REPO_FOLDER}/Dockerfile
cd ./bitwarden_rs
heroku container:push web -a $APP_NAME

echo "Now we can release the app which will publish it"
heroku container:release web -a $APP_NAME


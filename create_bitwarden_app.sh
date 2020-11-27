#!/bin/bash 
set -euo pipefail

# Clean out any existing contents
rm -rf ./bitwarden_rs

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
ENABLE_DUO=0
CREATE_APP_NAME=" "
GIT_HASH="master"
BITWARDEN_RS_FOLDER="bitwarden_rs"
STRATEGY_TYPE="deploy"

function git_clone {
    git_hash=$1
    echo "Clone current bitwarden_rs with depth 1"
    git clone --depth 1 https://github.com/dani-garcia/bitwarden_rs.git
    cd ./${BITWARDEN_RS_FOLDER}
    git checkout ${GIT_HASH}
    cd ..
}

function sed_files {
    sed -i "$1" "$2"
}

function heroku_bootstrap {

    CREATE_APP_NAME=$1

    echo "Logging into Heroku Container Registry to push the image (this will add an entry in your Docker config)"
    heroku container:login

    echo "We must create a Heroku application to deploy to first."
    APP_NAME=$(heroku create ${CREATE_APP_NAME} --json | jq --raw-output '.name')

    echo "We will use JawsDB Maria edition, which is free and sufficient for a small instance"
    heroku addons:create jawsdb -a $APP_NAME

    echo "Now we use the JAWS DB config as the database URL for Bitwarden"
    echo "Supressing output due to sensitive nature."
    heroku config:set DATABASE_URL=$(heroku config:get JAWSDB_URL -a $APP_NAME) -a $APP_NAME > /dev/null

    echo "Additionally set an Admin Token too in the event additional options are needed."
    echo "Supressing output due to sensitive nature."
    heroku config:set ADMIN_TOKEN=$(openssl rand -base64 48) -a $APP_NAME > /dev/null

    echo "And set DB connections to seven in order not to saturate the free DB"
    heroku config:set DATABASE_MAX_CONNS=7 -a $APP_NAME
}

function build_image {
    echo "Now we will build the amd64 image to deploy to Heroku with the specified port changes"
    mv ./${BITWARDEN_RS_FOLDER}/docker/amd64/Dockerfile ./${BITWARDEN_RS_FOLDER}/Dockerfile
    cd ./${BITWARDEN_RS_FOLDER}
    heroku container:push web -a $APP_NAME

    echo "Now we can release the app which will publish it"
    heroku container:release web -a $APP_NAME
}

while getopts d:a:g:t: flag
do
    case "${flag}" in
        d) ENABLE_DUO=${OPTARG};;
        a) CREATE_APP_NAME=${OPTARG};;
        g) GIT_HASH=${OPTARG};;
        t) STRATEGY_TYPE=${OPTARG};;
    esac
done
echo "Enable Duo: $ENABLE_DUO";
echo "Create App_Name: $CREATE_APP_NAME";
echo "Git Hash: $GIT_HASH";

git_clone $GIT_HASH

cd $SCRIPTPATH

echo "Heroku uses random ports for assignment with httpd services. We are modifying the ROCKET_PORT for startup."
sed_files '2 a export ROCKET_PORT=$PORT\n' ./${BITWARDEN_RS_FOLDER}/docker/start.sh

if [ $ENABLE_DUO -eq "1" ]
then
    echo "In order to maintain Duo with presistence for those who run replicas and have Duo enable by default, we modify the default config (src/config.rs) to enable Duo by default."
    sed_files 's/_enable_duo:            bool,   true,   def,     false;/_enable_duo:            bool,   true,   def,     true;/g' ./${BITWARDEN_RS_FOLDER}/src/config.rs
fi

echo "Modify netrc file to include Heroku details"
cat >~/.netrc <<EOF
machine api.heroku.com
    login ${HEROKU_EMAIL}
    password ${HEROKU_API_KEY}
machine git.heroku.com
    login ${HEROKU_EMAIL}
    password ${HEROKU_API_KEY}
EOF

if [[ ${STRATEGY_TYPE} = "deploy" ]]
then
    echo "Run Heroku bootstrapping for app and Dyno creations."
    heroku_bootstrap $CREATE_APP_NAME
else
    APP_NAME=$CREATE_APP_NAME
fi

build_image
echo "Congrats! Your new Bitwarden instance is ready to use! Head to Heroku, find the app, and use Open App to register!"
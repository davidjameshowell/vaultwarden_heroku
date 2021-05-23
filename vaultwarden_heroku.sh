#!/bin/bash 
set -euo pipefail

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

VAULTWARDEN_FOLDER="vaultwarden"
CREATE_APP_NAME=" "
ENABLE_AUTOBUS_BACKUP=0
ENABLE_DUO=0
GIT_HASH="main"
USE_PSQL=0
HEROKU_VERIFIED=0
OFFSITE_HEROKU_DB=" "
STRATEGY_TYPE="deploy"

# Clean out any existing contents
rm -rf ./${VAULTWARDEN_FOLDER}

function git_clone {
    GIT_HASH=$1
    echo "Clone current Vaultwarden with depth 1"
    git clone --depth 1 https://github.com/dani-garcia/vaultwarden.git
    cd ./${VAULTWARDEN_FOLDER}
    git checkout "${GIT_HASH}"
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
    APP_NAME=$(heroku create "${CREATE_APP_NAME}" ${HEROKU_CREATE_OPTIONS} --json | jq --raw-output '.name')
    if [ "$USE_PSQL" -eq "1" ]
    then
        echo "We will use Heroku Postgres, which is free and sufficient for a small instance"
        heroku addons:create heroku-postgresql -a "$APP_NAME"
        
        echo "Checking for additional addons"
        check_addons
    else
        if [ "${HEROKU_VERIFIED}" -eq "1" ]
        then
            echo "We will use JawsDB Maria edition, which is free and sufficient for a small instance"
            heroku addons:create jawsdb -a "$APP_NAME"
        
            echo "Checking for additional addons"
            check_addons
        
            echo "Now we use the JAWS DB config as the database URL for Bitwarden"
            echo "Supressing output due to sensitive nature."
            heroku config:set DATABASE_URL="$(heroku config:get JAWSDB_URL -a "${APP_NAME}")" -a "${APP_NAME}" > /dev/null
        else
            heroku config:set DATABASE_URL="${OFFSITE_HEROKU_DB}" -a "${APP_NAME}" > /dev/null
        fi
    fi
    
    echo "Additionally set an Admin Token too in the event additional options are needed."
    echo "Supressing output due to sensitive nature."
    heroku config:set ADMIN_TOKEN="$(openssl rand -base64 48)" -a "${APP_NAME}" > /dev/null

    echo "And set DB connections to seven in order not to saturate the free DB"
    heroku config:set DATABASE_MAX_CONNS=7 -a "${APP_NAME}"
    heroku config:set DOMAIN="https://${APP_NAME}.herokuapp.com" -a "${APP_NAME}"
}

function check_addons {

     if [ "${HEROKU_VERIFIED}" -eq "1" ]
     then
        # Check if Autobus is added
        if [ "${ENABLE_AUTOBUS_BACKUP}" -eq "1" ]
        then
            if (heroku addons -a "${APP_NAME}" | grep "autobus"); then
                echo "Autobus is enabled, skipping."
            else
                echo "Autobus is not enabled, enabling."
                echo "We will install AutoBus for database backup functionality now. AutoBus requires collaborator access to function."
                heroku access:add heroku@autobus.io -a "$APP_NAME" --permissions operate
                heroku addons:create autobus -a "$APP_NAME"
            fi
        fi
    fi
}

function build_image {
    git_clone "${GIT_HASH}"

    cd "${SCRIPTPATH}"

    echo "Heroku uses random ports for assignment with httpd services. We are modifying the ROCKET_PORT for startup."
    sed_files '2 a export ROCKET_PORT=$PORT\n' ./${VAULTWARDEN_FOLDER}/docker/start.sh

    if [ "${ENABLE_DUO}" -eq "1" ]
    then
        # Thank you bryanjhv!
        heroku config:set _ENABLE_DUO=true -a "${APP_NAME}"
    fi

    echo "Logging into Heroku Container Registry to push the image (this will add an entry in your Docker config)"
    heroku container:login

    echo "Now we will build the amd64 image to deploy to Heroku with the specified port changes"
    mv ./${VAULTWARDEN_FOLDER}/docker/amd64/Dockerfile ./${VAULTWARDEN_FOLDER}/Dockerfile
    cd ./${VAULTWARDEN_FOLDER}
    heroku container:push web -a "${APP_NAME}"

    echo "Now we can release the app which will publish it"
    heroku container:release web -a "${APP_NAME}"
}

function help {
    printf "Welcome to help!\Use option -a for app name,\n-d <0/1> to enable duo,\n -g to set a git hash to clone Vaultwarden from,\n and -t to specify if deployment or update!"
}

while getopts a:b:d:g:p:t:u:v: flag
do
    case "${flag}" in
        a) CREATE_APP_NAME=${OPTARG};;
        b) ENABLE_AUTOBUS_BACKUP=${OPTARG};;
        d) ENABLE_DUO=${OPTARG};;
        g) GIT_HASH=${OPTARG};;
        p) USE_PSQL=${OPTARG};;
        t) STRATEGY_TYPE=${OPTARG};;
        u) OFFSITE_HEROKU_DB=${OPTARG};;
        v) HEROKU_VERIFIED=${OPTARG};;
        *) HELP;;
    esac
done
echo "Enable Duo: $ENABLE_DUO";
echo "Create App_Name: $CREATE_APP_NAME";
echo "Git Hash: $GIT_HASH";
echo "Use PostgreSQL: $USE_PSQL";
echo "Heroku Verified: $HEROKU_VERIFIED";
echo "Enable Autobus Backup: $ENABLE_AUTOBUS_BACKUP";

if [[ ${STRATEGY_TYPE} = "deploy" ]]
then
    echo "Run Heroku bootstrapping for app and Dyno creations."
    heroku_bootstrap "${CREATE_APP_NAME}"
    APP_NAME=${CREATE_APP_NAME}
    build_image
    echo "Congrats! Your new Bitwarden instance is ready to use! Head to Heroku, find the app, and use Open App to register!"
elif [[ ${STRATEGY_TYPE} = "update" ]]
then
    APP_NAME=${CREATE_APP_NAME}
    check_addons
    build_image
else
    echo "Unexpected workflow, failing build"
    exit 1
fi

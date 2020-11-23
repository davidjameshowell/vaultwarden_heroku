# bitwarden_rs_heroku
Bitwarden_rs self hosted in Heroku for Free!

## Preface
In **[this issues request](https://github.com/dani-garcia/bitwarden_rs/issues/954)**, someone had inquired if it was possible to install Bitwarden_rs in Heroku. Unfortunately the dev team had not done this before and someone had tried but was unsccessful (due to port binding issues).

As my Bitwarden instance is a critical part of my daily workflow and part of acceptance from users in my group whom I need to share passwords with, high availability services are also an important part. I run a replica of Bitwarden on a cheap cloud server where I also take backups as well to S3, but seeing Heroku have a generous free tier, I was inclined to try this out!

## The script

The script in this repo is a quick and dirty implementation in order to get you started. It will make sure you have the required tooling to complete the process - if at any time you encounter an error, you will need to restart from scratch unfortuantely. This will be improved but is a first iterative step to get the script out there.

This script will make sure you have Heroku, are logged into Heroku, and also have the required tools (jq, heroku, Docker, openssl). Docker is required as we need to rebuild the image with a modified start.sh for the ROCKET_PORT. This will create the app (with a random name), add required addon Dynos, create the Docker image, deploy, and make sure the required essentials (ADMIN_TOKEN, DATABASE_URL) are in the environmental vars. 

Afterwards, you can login to your Heroku account and find your app and oepn the App URL to the new instance. 

Additionally, since this is DB backed, you can take backups (as JawsDB allows outside connections).

# Notes to consider

Your Bitwarden instance will go to sleep after 30 seconds of no activity. This should not be too bad of an issue due to the fact that you can maintain a local copy. However if you are adding, you may wish to have a cron job which polls your instance to keep it avaliable. 

The JawsDB instance comes with 5MB of storage space. I found this sufficient enough for my own personal backups even with 700+ entries, two orgs, and 4 members. You may find if you are attaching content, that you might exceed this but I suggest attach files in base64 encoded content to preserve portability.
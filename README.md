# bitwarden_rs_heroku
Bitwarden_rs self hosted in Heroku for Free!

## Preface
In **[this issues request](https://github.com/dani-garcia/bitwarden_rs/issues/954)**, someone had inquired if it was possible to install Bitwarden_rs in Heroku. Unfortunately the dev team had not done this before and someone had tried but was unsccessful (due to port binding issues).

As my Bitwarden instance is a critical part of my daily workflow and part of acceptance from users in my group whom I need to share passwords with, high availability services are also an important part. I run a replica of Bitwarden on a cheap cloud server where I also take backups as well to S3, but seeing Heroku have a generous free tier, I was inclined to try this out!

## The script

The script has heavily been reworked to utilize Github actions as a way of building and deploying, as well as updating the Bitwarden instance to latest version. Actions will go through the entire process with the settings you want and tweaks in order to Deploy out to Heroku without any extra resources on your end.

Please find in the .github/workflows/main.yml settings to set such as your Heroku application name, enable Duo global mode, and if you want to specifiy a specific Github has to use from bitwarden_rs to build from.

Please fork this repo and configure "HEROKU_APP_NAME", "HEROKU_EMAIL", and "HEROKU_API_KEY" in the Settings->Secrets tab. Once done, create a new deploy branch and push to deploy the application out. Afterwards, you can run updates manually via the main branch which will rebuild the container with the assigned settings, push, and release as a new version to Heroku.

After initial deployment, you can login to your Heroku account and find your app and open the App URL to the new instance. 

Additionally, since this is DB backed, you can take backups (as JawsDB allows outside connections).

# Notes to consider

Your Bitwarden instance will go to sleep after 30 minutes of no activity. This should not be too bad of an issue due to the fact that you can maintain a local copy. However if you are adding, you may wish to have a cron job which polls your instance to keep it avaliable (read: Pingdom set to 15 minute intervals or any website status checker).

The JawsDB instance comes with 5MB of storage space. I found this sufficient enough for my own personal backups even with 700+ entries, two orgs, and 4 members. You may find if you are attaching content, that you might exceed this but I suggest attach files in base64 encoded content to preserve portability.
**THIS PROJECT WAS RENAMED FROM BITWARDEN_RS_HEROKU TO VAULTWARDEN_HEROKU TO MATCH UPSTREAM PROJECT NAME**

# Vaultwarden on Heroku for Free!
Deploy Vaultwarden in Heroku for free via Github

![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/davidjameshowell/vaultwarden_heroku/VaultwardenOnHeroku_Deploy/main?label=Deploy%20Vaultwarden&style=for-the-badge)
![GitHub Workflow Status (branch)](https://img.shields.io/github/workflow/status/davidjameshowell/vaultwarden_heroku/VaultwardenOnHeroku_Update/main?label=Update%20Vaultwarden&style=for-the-badge)

[![CodeFactor](https://www.codefactor.io/repository/github/davidjameshowell/vaultwarden_heroku/badge)](https://www.codefactor.io/repository/github/davidjameshowell/vaultwarden_heroku)

## Features
* Build and deploy cutomized Vaultwarden image from source to Heroku via Github actions
* Add global Duo Security enablement for replica deployment as needed
* Maintanable updates with Git Hash for future updates
* Easily extendable for future tweaks

## Usage

Usage is simple, fast, and user friendly!

### Deployment

1. Create a fork of this project
2. Edit the `.github/workflows/deploy.yml` to enable/disable Duo and/or modify the checkout hash of Vaultwarden upstream.
3. Go to your forked repo Settings > Secrets and add secrets for:
  * HEROKU_API_KEY (yoru Heroku API key - can be found in **[Account Setings](https://dashboard.heroku.com/account)** -> APi Keys)
  * HEROKU_APP_NAME (the name of the Heroku application, this must be unqiue across Heroku and will fail if it is not) [Value alphanumerical]
  * **HEROKU_VERIFIED (required regardless, if you have added a credit card on, your account will be verified to use built in addons, if not please see "NON VERIFIED ACCOUNTS" section)** [Value 0/1]
4. Go to the Actions tab, select the BitwardenRSOnHerokuAIO_Deploy job and wait!
5. Github Actions will run the job and begin deploying the app. This will take around 15 minutes.
6. Congrats, you now having a fully functional Vaultwarden instance in Heroku!
 
 ### Update
 
 Updating is simple and can be done one of two ways:
 * Running the workflow manually via Github Actions
 * Making a commit to the main branch, forcing a Github Actions workflow to initiate
 
Either one of these will force the Github Actions workflow to run and update the app. If you need to modify to enable/disable settings, you should re run it as well.

## Non Verified Heroku Accounts
Non-verified Heroku accounts cannot use the built in Heroku addons, regardless if they are free or not. This just requires you to do a few more steps and use an outside resources. I have not personally vetted this service, but [FreeMySQLHosting](https://www.freemysqlhosting.net/) has free plans comparable to the JawsDB addon and should be sufficient for usage. It is suggested that regardless of whatever route you take, you take regular constructed backups of your Bitwarden Vault for safety. 

Another service that @mizzunet has found working is [freedb.tech](https://freedb.tech). He has indicated successfuly results and they do not currently cap MySQL connections.

Signup via the website above and navigate to the home page, select your home region for database ("Select where you would like you database located.") and then create database. It will list the server hostname and relevant details. The password will be emailed to you. You will need to add a new Github repository secret for "OFFSITE_HEROKU_DB" in the format of `mysql://USERNAME:PASSWORD@SERVER_HOSTNAME:SERVER_PORT/DATABASE_NAME`. If this field is not filled out properly, you will encounter issues and may be troublesome to debug. Verified users of Heroku benefit from having easier settup without issues. Additionally, you will need to modify `HEROKU_VERIFIED` to 0 in order to trigger the offsite DB env var.

## Why this was started
In **[this issues request](https://github.com/dani-garcia/Vaultwarden/issues/954)**, someone had inquired if it was possible to install Vaultwarden in Heroku. Unfortunately the dev team had not done this before and someone had tried but was unsccessful (due to port binding issues).

As my Bitwarden instance is a critical part of my daily workflow and part of acceptance from users in my group whom I need to share passwords with, high availability services are also an important part. I run a replica of Bitwarden on a cheap cloud server where I also take backups as well to S3, but seeing Heroku have a generous free tier, I was inclined to try this out!

# Notes to consider

Your Bitwarden instance will go to sleep after 30 minutes of no activity. This should not be too bad of an issue due to the fact that you can maintain a local copy. However if you are adding, you may wish to have a cron job which polls your instance to keep it avaliable (read: Pingdom set to 15 minute intervals or any website status checker).

The JawsDB instance comes with 5MB of storage space. I found this sufficient enough for my own personal backups even with 700+ entries, two orgs, and 4 members. You may find if you are attaching content, that you might exceed this but I suggest attach files in base64 encoded content to preserve portability.

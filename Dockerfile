## debian is an official account of docker on dockerhub, buster is the name of the latest version (10)

FROM debian:buster

## run execute commands
## debian DEBIAN_FRONTEND skips prompts during installation (no popups!)
## update / upgrade/ dist-upgrade assures we run the latest version of
## everything (packages and sytemp DISTribution)
## -y accepts automatically (confirmation prompt when running upgrades and such)
## nginx web server
## php is for phpmyadmin
## wget to get files from the internet
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade && apt-get -y install nginx wordpress php wget

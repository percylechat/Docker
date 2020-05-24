## debian is an official account of docker on dockerhub, buster is the name
## of the latest version (10)

FROM debian:buster

## run execute commands
## debian DEBIAN_FRONTEND skips prompts during installation (no popups!)
## update / upgrade/ dist-upgrade assures we run the latest version of
## everything (packages and sytemp DISTribution)
## -y accepts automatically (confirmation prompt when running upgrades and such)
## nginx web server
## php is for phpmyadmin
## wget to get files from the internet
## unzip install a zipper
## lsb-release gnupg needed for mysql

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade && apt-get -y install nginx wordpress php wget unzip lsb-release gnupg

## change env variable to not have prompts

RUN export DEBIAN_FRONTEND=noninteractive

## download mysql from internet

RUN wget http://repo.mysql.com/mysql-apt-config_0.8.13-1_all.deb

##dpkg debian packages
##-i install

RUN dpkg -i mysql-apt-config_0.8.13-1_all.deb

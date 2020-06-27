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
## sudo is user manager
## see php doc
## procps enables pkill command
## curl to install wpcli
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade && apt-get -y install nginx php wget unzip lsb-release gnupg sudo php-fpm php-mysql procps curl

## remove and purge apache2 so nginx can take its place
RUN DEBIAN_FRONTEND=noninteractive apt-get -y remove apache2 && apt-get -y purge apache2

## download mysql from internet
RUN wget http://repo.mysql.com/mysql-apt-config_0.8.13-1_all.deb

## need to change environnement again because changes back for each command
## dpkg debian packages
## -i install
RUN DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.13-1_all.deb

## remove deb file to clean
RUN rm mysql-apt-config_0.8.13-1_all.deb

## upgrade once again to include mysql installation servers
RUN apt-get update

## install servers for mysql
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-community-client mysql-server

## create script directory to store files
RUN mkdir /script

## create database for mysql users
RUN echo "CREATE DATABASE wordpress_db;" > /script/config_mysql.sql

## set password for root, create user for wp database and grants rights
## last line to resolve conflict with wordpress/mysql/php versions
RUN echo "CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'bebechat';" >> /script/config_mysql.sql
RUN echo "GRANT ALL PRIVILEGES ON wordpress_db.* TO 'wp_user'@'localhost';" >> /script/config_mysql.sql
RUN echo "UPDATE mysql.user SET authentication_string=null WHERE User='root';" >> /script/config_mysql.sql
RUN echo "FLUSH PRIVILEGES;" >> /script/config_mysql.sql
RUN echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'bebechat';" >> /script/config_mysql.sql
RUN echo "ALTER USER 'wp_user'@'localhost' IDENTIFIED WITH mysql_native_password BY 'bebechat';" >> /script/config_mysql.sql

## WARNING to be done at the end of mysql configurations
## #!bin/bash is shebang which helps computer to understand that this is not a binary file and to use bin/bash to execute sc script
## create a script repository and a install.sh executable file to exec command and start processes
## pretends to be mysql user and start server in background
RUN echo "#!/bin/bash\nsudo -u mysql /usr/sbin/mysqld & > /dev/null 2>&1" > /script/install.sh && chmod +x /script/install.sh
RUN echo "while ! mysqladmin ping -h localhost -u root; do\n    sleep 1\ndone\n" >> /script/install.sh

## database creation put in a script, launched as user mysql in root. Will go on when docker is run
RUN echo "mysql -u root < /script/config_mysql.sql" >> /script/install.sh

## install and configure wordpress throught automated script called wpcli. standatrd use would include downloading the wp tar file and manually modifying values in cinfig files thanks to grep and such
RUN echo "curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp" >> /script/install.sh
RUN echo "cd /var/www/html && mkdir wordpress && cd wordpress && wp --allow-root core download " >> /script/install.sh
RUN echo "cd /var/www/html/wordpress && wp --allow-root core config --dbname=wordpress_db --dbuser=wp_user --dbpass=bebechat " >> /script/install.sh
RUN echo "cd /var/www/html/wordpress && wp --allow-root core install --url=https://127.0.0.1/wordpress/ --title=WordPress --admin_user=admin --admin_password=bebechat --admin_email=adminwp@yopmail.com " >> /script/install.sh

## download phpmyadmin, unzip, remove archive and rename directory
RUN echo "cd /var/www/html/ && wget https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-english.tar.gz && tar -xvzf phpMyAdmin-5.0.2-english.tar.gz && rm phpMyAdmin-5.0.2-english.tar.gz && mv phpMyAdmin-5.0.2-english phpmyadmin">> /script/install.sh

## create config file with a blowfish encryption key
RUN echo "cd /var/www/html/phpmyadmin && mv config.sample.inc.php config.inc.php && ">> /script/install.sh
RUN echo "sed -i \"s/\['blowfish_secret'\] = ''/\['blowfish_secret'\] = 'fHYA58Vfa1n7sj3kSKBR5Lmh502htSTN'/\" /var/www/html/phpmyadmin/config.inc.php">> /script/install.sh

##RUN echo "">> /script/install.sh

## kill server so it can be set up
RUN echo "pkill mysqld" >> /script/install.sh

RUN bash /script/install.sh

## replace the way php fmp interprets fils so that it won't run the neareast php file if the one searched isn't found. Helps with security in case someone tries to send a php script.
## WARNING, path is absolute until next php version which could change the version and thus the path name
RUN sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.3/fpm/php.ini

## start cgi manager of php for nginx so previous changes are applied
RUN echo "#!/bin/bash\n/etc/init.d/php7.3-fpm start &"> /script/run.sh

## tells nginx to take into account an index.php file for display
RUN sed -i 's/index index.html index.htm index.nginx-debian.html;/index index.php index.html index.htm index.nginx-debian.html;/g' /etc/nginx/sites-available/default

## first delete useless lines, then tells nginx to process php files through php fpm and also forbids the display of ht files (containing rights and passwords!)
RUN sed -i '53,94d' /etc/nginx/sites-available/default
RUN echo "location ~ \.php$ {\n\tinclude snippets/fastcgi-php.conf;\n\tfastcgi_pass unix:/run/php/php7.3-fpm.sock;\n}\nlocation ~ /\.ht {\n\tdeny all;\n}\n}" >> /etc/nginx/sites-available/default
RUN sed -i 's/server_name _;/server_name localhost;/g' /etc/nginx/sites-available/default

## generate ssl certificate and keys
RUN printf 'FR\ncastle\nchair\nbabt\ntest\nhelp\nend\n' | openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt

## create Diffie-Hellman group
RUN openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096

## confing nginx with ssl
RUN echo "ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;" > /etc/nginx/snippets/self-signed.conf
RUN echo "ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;" >> /etc/nginx/snippets/self-signed.conf
RUN echo "ssl_protocols TLSv1 TLSv1.1 TLSv1.2;ssl_prefer_server_ciphers on;ssl_ciphers \"EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH\";ssl_ecdh_curve secp384r1;ssl_session_cache shared:SSL:10m;ssl_session_tickets off;ssl_stapling off;ssl_stapling_verify on;resolver 8.8.8.8 8.8.4.4 valid=300s;resolver_timeout 5s;add_header Strict-Transport-Security \"max-age=63072000; includeSubdomains\";add_header X-Frame-Options DENY;add_header X-Content-Type-Options nosniff;ssl_dhparam /etc/ssl/certs/dhparam.pem;" > /etc/nginx/snippets/ssl-params.conf
RUN cd /etc/nginx/sites-available/ && sed -i 's/\# listen/listen/g' default && sed -i '22,23d' default && sed -i '26a\ include snippets/self-signed.conf;' default && sed -i '27a\include snippets/ssl-params.conf; ' default
RUN echo "server{\n \tlisten 80;\n\tlisten [::]:80;\n\tserver_name localhost;\n\treturn 301 https://\$server_name\$request_uri;\n}" >> /etc/nginx/sites-available/default

## rename old index file so it's not taken into account
RUN mv /var/www/html/index.nginx-debian.html /var/www/html/old-index.nginx-debian.html

##create index.html for convenienty
RUN cd /var/www/html && touch index.html
RUN echo "<html><body><p><a href="/wordpress">Wordpress</a></p><p><a href="/phpmyadmin">Phpmyadmin</a></p></body></html>" >> /var/www/html/index.html

RUN echo "nginx &" >> /script/run.sh

RUN echo "sudo -u mysql /usr/sbin/mysqld" >> /script/run.sh && chmod +x /script/run.sh

## END: configure and download systemctl to make sure that interrupted processes can be restarted automatically

## WARNING, passwords will be defined as env variables in user computer. SO need to define them before building docker!

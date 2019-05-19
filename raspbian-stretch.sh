#!/bin/bash
# written by iOSMAN
# https://github.com/iOSMANzZz/LEMP/

if [ "$(whoami)" != "root" ]; then
	echo "Run script as ROOT please. (sudo !!)"
	exit
fi

clear
while true; do
    echo "NOTE: Do NOT type local ip adress (192.168.x.x & 172.0.0.1) X"
    read -p "Please type the domain what you want to create on nginx. <type & enter> " domain
    case $domain in
	[0]* ) nginx=0; break;;
	*.* ) nginx=1; uzanti='.html'; break;;
        * ) echo "Please type your domain or ip adress (not local). <domain.tld or x.x.x.x>";;
    esac
done

while true; do
    read -p "Do you want to run system upgrade? <y/N> " upgrade
    case $upgrade in
        [Yy]* ) upgrade=1; break;;
        [Nn]* ) upgrade=0; break;;
        * ) echo "Please answer yes or no.  <yY/nN>";;
    esac
done

while true; do
    read -p "Do you want to install PHP? <y/N> " php
    case $php in
        [Yy]* ) php=1; uzanti='.php'; phpcode='<?php phpinfo(); ?>'; indexphp=" index.php"; break;;
        [Nn]* ) php=0; phpis="#"; break;;
        * ) echo "Please answer yes or no.  <yY/nN>";;
    esac
done

while true; do
    read -p "Do you want to install MariaDB? <y/N> " mariadb
    case $mariadb in
        [Yy]* ) mariadb=1; break;;
        [Nn]* ) mariadb=0; break;;
        * ) echo "Please answer yes or no.  <yY/nN>";;
    esac
done

while true; do
    read -p "Do you want to install phpMyAdmin? <y/N> " pma
    case $pma in
        [Yy]* ) pma=1; break;;
        [Nn]* ) pma=0; break;;
        * ) echo "Please answer yes or no.  <yY/nN>";;
    esac
done

echo "	Updating repository"
apt update -y

if [ "$upgrade" = "1" ]; then
echo "	Upgrading system"
apt upgrade -y
apt dist-upgrade -y
echo "	Upgrading firmware"
apt install -y rpi-update
fi
if [ "$nginx" = "1" ]; then

echo "	Installing nginx"
apt install -y nginx
update-rc.d nginx defaults
echo "	Setting up nginx"
sed -i 's/# server_names_hash_bucket_size/server_names_hash_bucket_size/' /etc/nginx/nginx.conf 


uri='$uri'
cat > /etc/nginx/sites-available/default <<EOF
# Default server
server {
	listen 80 default_server;
	listen [::]:80 default_server;
	
	server_name _;
	root /var/www/default/public;
	index$indexphp index.html index.htm default.html;

	location / {
		try_files $uri $uri/ =404;
	}

	# the PHP scripts to FastCGI server
	$phpis location ~ \.php$ {
	$phpis	include snippets/fastcgi-php.conf;
	$phpis	fastcgi_pass unix:/run/php/php7.0-fpm.sock;
	$phpis }

	# optimize static file serving
	location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml)$ {
		access_log off;
		log_not_found off;
		expires 30d;
	}

	# deny access to .htaccess files, should an Apache document root conflict with nginx
	location ~ /\.ht {
		deny all;
	}
}

# $domain server configuration
server {
	listen 80;
	listen [::]:80;
	
	server_name $domain www.$domain;
	root /var/www/$domain/public;
	index$indexphp index.html index.htm default.html;

	location / {
		try_files $uri $uri/ =404;
	}

        # the PHP scripts to FastCGI server
        $phpis location ~ \.php$ {
        $phpis  include snippets/fastcgi-php.conf;
        $phpis  fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        $phpis }
	
	# optimize static file serving
	location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml)$ {
		access_log off;
		log_not_found off;
		expires 30d;
	}

	# deny access to .htaccess files, should an Apache document root conflict with nginx
	location ~ /\.ht {
		deny all;
	}
}
EOF

mkdir -p /var/www/default/public
cat > /var/www/default/public/index$uzanti <<EOF
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<center><h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</center>
$phpcode
</body>
</html>
EOF

mkdir -p /var/www/$domain/public
cat > /var/www/$domain/public/index$uzanti <<EOF
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<center><h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</center>
$phpcode
</body>
</html>
EOF

usermod -a -G www-data pi
chown -R pi:www-data /var/www
chgrp -R www-data /var/www
chmod -R g+rw /var/www

nginx -t
service nginx restart
fi
if [ "$php" = "1" ]; then
echo "	Installing PHP 7"
apt install -y php7.0 php7.0-fpm php7.0-cli php7.0-opcache php7.0-mbstring php7.0-curl php7.0-xml php7.0-gd php7.0-mysql php7.0-zip
echo "	Setting up PHP 7"
update-rc.d php7.0-fpm defaults
sed -i 's/^;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/7.0/fpm/php.ini
service php7.0-fpm restart
fi
if [ "$mariadb" = "1" ]; then
echo "	Installing MariaDB"
apt -y install mariadb-server
echo "	Setting up MariaDB"
mysql_secure_installation
service mysql restart
fi
if [ "$pma" = "1" ]; then
echo "	Installing phpMyAdmin"
apt install -y phpmyadmin
echo "	Setting up phpMyAdmin"
ln -s /usr/share/phpmyadmin /var/www/default/public
EOF=$( ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/' )
echo "http://$EOF/phpmyadmin to enter PhpMyAdmin"
fi
apt -y autoremove

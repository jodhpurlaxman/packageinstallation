#!/bin/bash
ok() { echo -e '\e[32m'$1'\e[m'; } # Green

if [[ $EUID -ne 0 ]]; then
   ok "This script must be run as root" 
   exit 1
fi
apt update
apt-get install -y software-properties-common curl gcc g++ make
add-apt-repository ppa:ondrej/apache2 -y
add-apt-repository ppa:ondrej/php -y
apt install 
curl -sL https://deb.nodesource.com/setup_12.x | -E bash -
apt update
apt-get install -y git filezilla cifs-utils unzip bind9 resolvconf openssh-server composer nodejs git build-essential libtool autoconf openssl mysql-server-5.7 apache2 libapache2-mpm-itk php-pear php5.6 php7.0 php7.1 php7.2 php7.3 php7.4 php5.6-fpm php7.0-fpm php7.1-fpm php7.2-fpm php7.3-fpm php7.4-fpm \
php5.6-{curl,common,xml,bcmath,bz2,intl,gd,mbstring,mysql,zip,json} \
php7.0-{curl,common,xml,bcmath,bz2,intl,gd,mbstring,mysql,zip,json} \
php7.1-{curl,common,xml,bcmath,bz2,intl,gd,mbstring,mysql,zip,json} \
php7.2-{curl,common,xml,bcmath,bz2,intl,gd,mbstring,mysql,zip,json} \
php7.3-{curl,common,xml,bcmath,bz2,intl,gd,mbstring,mysql,zip,json} \
php7.4-{curl,common,xml,bcmath,bz2,intl,gd,mbstring,mysql,zip,json} \
phpmyadmin
#===================================================PHPFPM========================================================
cat << EOT >  /etc/apache2/conf-available/php-fpm.conf
<IfModule mod_fastcgi.c>
        AddHandler php7-fcgi .php
        Action php7-fcgi /php7-fcgi
        Alias /php7-fcgi /usr/lib/cgi-bin/php7-fcgi
        FastCgiExternalServer /usr/lib/cgi-bin/php7-fcgi -socket /run/php/php7.2-fpm.sock -pass-header Authorization -idle-timeout 60
        <Directory /usr/lib/cgi-bin>
                Require all granted
        </Directory>
</IfModule>
EOT

a2enmod "proxy proxy_fcgi setenvif actions alias auth_basic env expires headers http2 mime ssl rewrite request mpm_itk"
a2enconf  "php-fpm php5.6-fpm php7.0-fpm php7.1-fpm  php7.2-fpm php7.3-fpm phpmyadmin"



#==================================*MySql User database*===========================================
mysql -e "CREATE DATABASE IF NOT EXISTS QD_TEST; GRANT ALL PRIVILEGES ON *.* TO 'quallitydev'@'localhost' IDENTIFIED BY 'password'; FLUSH PRIVILEGES;"
Q3="FLUSH PRIVILEGES;"

ok "Database QD_TEST and user quallitydev created with a password password"
#=============================================WORDPRESS=====================================================
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar '/usr/local/bin/wp'

#============================================================================================================
cat << EOT >   /etc/bind/named.conf.local
zone "quallitydev.in" {
        type master;
        file "/etc/bind/zones/quallitydev.in";
        allow-update { none; };
 };
zone "0.127.in-addr.arpa" {
        type master;
        file "/etc/bind/zones/rev.quallitydev.in";
        allow-update { none; };
 };
EOT
cat << EOT > /etc/bind/named.conf.options
options {
        directory "/var/cache/bind";
        recursion yes;
         forwarders {
                8.8.8.8;
                8.8.4.4;
         };
        dnssec-validation auto;
        auth-nxdomain no;    # conform to RFC1035
        listen-on-v6 { any; };
};
EOT
cat << EOT >> /etc/bind/named.conf.local
zone "qualdev.in" {
        type master;
        file "/etc/bind/zones/quallitydev.in";
        allow-update { none; };
 };
EOT
#============
mkdir /etc/bind/zones
#wget https://raw.githubusercontent.com/jodhpurlaxman/packageinstallation/master/quallitydev.in
#wget https://raw.githubusercontent.com/jodhpurlaxman/packageinstallation/master/rev.quallitydev.in
mv qualdev.in /etc/bind/zones/qualdev.in
mv rev.qualdev.in /etc/bind/zones/rev.qualdev.in
mv test.net /etc/bind/zones/test.net
service	bind9 restart
#=========================
cat << EOT >> /etc/hosts
127.0.0.1 ns1.qualdev.in ns2.qualdev.in ns1 ns2
EOT
#=========================
cat << EOT > /etc/resolvconf/resolv.conf.d/head
nameserver 127.0.0.1
EOT
service resolvconf restart
#=======================================
dig @127.0.0.1
ok  "dig qualdev.in A"
dig qualdev.in A
ok  "updating php.ini in all PHPFPM version"
#wget https://github.com/jodhpurlaxman/packageinstallation/blob/master/php5.6.conf
#wget https://github.com/jodhpurlaxman/packageinstallation/blob/master/php7.0.conf
#wget https://github.com/jodhpurlaxman/packageinstallation/blob/master/php7.1.conf
#wget https://github.com/jodhpurlaxman/packageinstallation/blob/master/php7.2.conf
#wget https://github.com/jodhpurlaxman/packageinstallation/blob/master/php7.3.conf
#wget https://github.com/jodhpurlaxman/packageinstallation/blob/master/php7.4.conf
#wget https://github.com/jodhpurlaxman/packageinstallation/blob/master/php-fpm.conf
#wget https://github.com/jodhpurlaxman/packageinstallation/blob/master/openssl.zip
unzip openssl.zip
mkdir /etc/ssl/selfsigned
cp openssl/ca-bundle.pem /etc/ssl/selfsigned/ca-bundle.pem
mv test.net.conf /etc/apache2/sites-available/test.net.conf
mv php5.6.conf /etc/php/5.6/fpm/php.ini
mv php7.0.conf /etc/php/7.0/fpm/php.ini
mv php7.1.conf /etc/php/7.1/fpm/php.ini
mv php7.2.conf /etc/php/7.2/fpm/php.ini
mv php7.3.conf /etc/php/7.3/fpm/php.ini
mv php7.4.conf /etc/php/7.4/fpm/php.ini
mv php-fpm7.4.conf /etc/php/7.4/fpm/pool.d/www.conf
ok "Rewrite setting in apache.conf"
sed -i '/#<Directory/i \
<Directory /home/*/public_html/> \
Options Indexes FollowSymLinks \
AllowOverride ALL \
Require all granted \
</Directory>' /etc/apache2/apache2.conf
mkdir -p /home/it/public_html/test.net/public
mkdir -p /home/it/public_html/logs
ok  "updating restarting PHP-FPM ALL VERSIONS"
ok  "Enabling test vhost test.net"

a2ensite test.net service php5.6-fpm restart && service php7.0-fpm restart && service php7.1-fpm restart && service php7.2-fpm restart && service php7.3-fpm restart && service php7.3-fpm restart && service apache2 restart
ok  "Enabling SSH ON SERVER"
sed -i 's/#   Port 22/Port 22/g' /etc/ssh/ssh_config

systemctl enable apache2 && systemctl enable php5.6-fpm && systemctl enable php7.0-fpm &&  systemctl enable php7.1-fpm &&  systemctl enable php7.2-fpm && systemctl enable php7.3-fpm && systemctl enable php7.3-fpm && systemctl enable mysql && systemctl enable bind9 && systemctl enable ssh && systemctl restart ssh















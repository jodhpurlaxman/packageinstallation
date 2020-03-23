#!/bin/bash
ok() { echo -e '\e[32m'$1'\e[m'; } # Green

sudo apt-get install -y software-properties-common curl gcc g++ make
sudo add-apt-repository ppa:ondrej/apache2 -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt install 
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt update
sudo apt-get install -y git filezilla cifs-utils unzip bind9 resolvconf openssh-server composer nodejs git build-essential libtool autoconf openssl mysql-server-5.7 apache2 libapache2-mpm-itk php-pear php5.6 php7.0 php7.1 php7.2 php7.3 php7.4 php5.6-fpm php7.0-fpm php7.1-fpm php7.2-fpm php7.3-fpm php7.4-fpm \
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

sudo a2enmod "proxy proxy_fcgi setenvif actions alias auth_basic env expires headers http2 mime ssl rewrite request mpm_itk"
sudo a2enconf  "php-fpm php5.6-fpm php7.0-fpm php7.1-fpm  php7.2-fpm php7.3-fpm phpmyadmin"



#==================================*MySql User database*===========================================
mysql -e "CREATE DATABASE IF NOT EXISTS QD_TEST; GRANT ALL PRIVILEGES ON *.* TO 'qualdev'@'localhost' IDENTIFIED BY 'P@q2w3efg'; FLUSH PRIVILEGES;"
Q3="FLUSH PRIVILEGES;"

ok "Database QD_TEST and user qualdev created with a password P@q2w3fg"
#=============================================WORDPRESS=====================================================
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar '/usr/local/bin/wp'

#============================================================================================================
cat << EOT >   /etc/bind/named.conf.local
zone "qualdev.in" {
        type master;
        file "/etc/bind/zones/qualdev.in";
        allow-update { none; };
 };
zone "0.127.in-addr.arpa" {
        type master;
        file "/etc/bind/zones/rev.qualdev.in";
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
        file "/etc/bind/zones/qualdev.in";
        allow-update { none; };
 };
#============
mkdir /etc/bind/zones
#wget https://raw.githubusercontent.com/jodhpurlaxman/packageinstallation/master/qualdev.in
#wget https://raw.githubusercontent.com/jodhpurlaxman/packageinstallation/master/rev.qualdev.in
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
sudo service resolvconf restart
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
cp ca-bundle.pem /etc/ssl/selfsigned/

mv php5.6.conf /etc/php/5.6/fpm/php.ini
mv php7.0.conf /etc/php/7.0/fpm/php.ini
mv php7.1.conf /etc/php/7.1/fpm/php.ini
mv php7.2.conf /etc/php/7.2/fpm/php.ini
mv php7.3.conf /etc/php/7.3/fpm/php.ini
mv php7.4.conf /etc/php/7.4/fpm/php.ini
mv php-fpm7.4.conf /etc/php/7.4/fpm/pool.d/www.conf


ok  "updating restarting PHP-FPM ALL VERSIONS"
sudo service php5.6-fpm restart && sudo service php7.0-fpm restart && sudo service php7.1-fpm restart && sudo service php7.2-fpm restart && sudo service php7.3-fpm restart && sudo service php7.3-fpm restart && sudo service apache2 restart
sed -i 's/#   Port 22/Port 22/g' /etc/ssh/sshd_config
systemctl enable apache2 && systemctl enable php5.6-fpm && systemctl enable php7.0-fpm &&  systemctl enable php7.1-fpm &&  systemctl enable php7.2-fpm && systemctl enable php7.3-fpm && systemctl enable php7.3-fpm && systemctl enable mysql && systemctl enable bind9















#!/bin/bash
ok() { echo -e '\e[32m'$1'\e[m'; } # Green

sudo apt-get install -y software-properties-common curl gcc g++ make
sudo add-apt-repository ppa:ondrej/apache2 -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt install 
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt update
sudo apt-get install -y git filezilla cifs-utils unzip bind9 resolvconf openssh-server composer nodejs git build-essential libtool autoconf openssl mysql-server-5.7 apache2 libapache2-mpm-itk php-pear php5.6 php7.0 php7.1 php7.2 php7.3 php7.4 php5.6-fpm php7.0-fpm php7.1-fpm php7.2-fpm php7.3-fpm php7.4-fpm \
php5.6-{dev,curl,common,xml,bcmath,bz2,intl,gd,mbstring,mysql,zip,json} \
php7.0-{dev,curl,common,xml,bcmath,bz2,intl,gd,mbstring,mysql,zip,json} \
php7.1-{dev,curl,common,xml,bcmath,bz2,intl,gd,mbstring,mysql,zip,json} \
php7.2-{dev,curl,common,xml,bcmath,bz2,intl,gd,mbstring,mysql,zip,json} \
php7.3-{dev,curl,common,xml,bcmath,bz2,intl,gd,mbstring,mysql,zip,json} \
php7.4-{dev,curl,common,xml,bcmath,bz2,intl,gd,mbstring,mysql,zip,json} \
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
</IfModule>"
EOT

sudo a2enmod "proxy proxy_fcgi setenvif actions alias auth_basic env expires headers http2 mime ssl rewrite request mpm_itk"
sudo a2enconf  "php-fpm php5.6-fpm php7.0-fpm php7.1-fpm  php7.2-fpm php7.3-fpm phpmyadmin"
sudo service php5.6-fpm restart && sudo service php7.0-fpm restart && sudo service php7.1-fpm restart && sudo service php7.2-fpm restart && sudo service php7.3-fpm restart && sudo service php7.3-fpm restart && sudo service apache2 restart


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
#============
mkdir /etc/bind/zones
touch /etc/bind/zones/qualdev.in
touch /etc/bind/zones/rev.qualdev.in
cat << EOT >   /etc/bind/zones/qualdev.in
$TTL 86400;
$ORIGIN qualdev.in.
@ 1D IN  SOA     ns1.qualdev.in. postmaster.qualdev.in. (
        1  ;Serial
        600        ;Refresh
        600        ;Retry
        604800      ;Expire
        900       ;Minimum TTL
)
        IN      NS      ns1.qualdev.in.
        IN      NS      ns2.qualdev.in.
;Name Server
ns2     IN  A      127.0.0.1
ns1     IN  A      127.0.0.1
;address to name mapping
@                IN A      127.0.0.1
;Mail Server
@               IN  MX          0       ns1
;Aliashed Servers
www             IN  A           127.0.0.1
EOT
#=========================
cat << EOT > /etc/bind/zones/rev.qualdev.in
$TTL    900
@       IN      SOA     ns1.qualdev.in. postmaster.qualdev.in. (
                                2       ;<serial-number>
                              900       ;<time-to-refresh>
                              900       ;<time-to-retry>
                           604800       ;<time-to-expire>
                              900)      ;<minimum-TTL>
; name servers
      IN      NS      ns1.qualdev.in.
      IN      NS      ns1.qualdev.in.

; PTR Records
101   IN      PTR     ns1.            ; 127.0.0.1
101   IN      PTR     ns2.             ; 127.0.0.1
EOL

service	bind9 restart
#=========================
cat << EOT > /etc/hosts
127.0.0.1 ns1.qualdev.in ns2.qualdev.in ns1 ns2
EOT
#=========================
cat << EOT > /etc/resolvconf/resolv.conf.d/head
nameserver 127.0.0.53
nameserver 8.8.4.4
nameserver 8.8.8.8
EOT
sudo service resolvconf restart
#=======================================
dig @127.0.0.1
dig qualdev.in A 


#!/bin/bash
serverIP=192.168.222.19
HOSTNAMESHORT=proxmox
HOSTNAMEFQDN=proxmox.inattendu-lab.org
mysql_pass=toor
phpma_pass=toor
echo " _____________________________"
echo "|                             |"
echo "| Scrip de configuration v0.4 |"
echo "| by inattendu                |"
echo "|_____________________________|"
echo ""
echo ""
echo " * NOMMAGE"
rm /etc/hosts
echo -e '127.0.0.1\t\t'$HOSTNAMEFQDN'\t'$HOSTNAMESHORT'\t localhost' >> /etc/hosts
echo -e $serverIP'\t\t'$HOSTNAMEFQDN'\t'$HOSTNAMESHORT >> /etc/hosts
echo "    --> Fichier HOSTS"
echo $HOSTNAMEFQDN > /etc/hostname
echo "    --> Fichier HOSTNAME"
/etc/init.d/hostname.sh >> isp.log 2>&1
echo "    --> Actualisation"
echo "---------------------------"
echo " * [PREPARATION DU SYSTEME]"
echo "    --> Actualisation des sources"
cat > /etc/apt/sources.list <<EOF
deb http://ftp.fr.debian.org/debian/ jessie main contrib non-free
deb http://security.debian.org/ jessie/updates main contrib non-free
deb http://ftp.fr.debian.org/debian/ jessie-updates main contrib non-free
EOF
echo "    --> Mise à jour"
apt-get -q clean >> isp.log 2>&1 && apt-get -qq update >> isp.log 2>&1 && apt-get -y -qq dist-upgrade >> isp.log 2>&1 && apt-get -qq autoremove --purge >> isp.log 2>&1
echo "    --> Installation d'outils initiaux (archivage, DNS, NTP, rkhunter, sudo)"
apt-get -y -qq install dnsutils unzip rkhunter binutils sudo bzip2 zip ntp ntpdate >> isp.log 2>&1
echo "    --> Reconfiguration du terminal vers DASH"
echo "dash dash/sh boolean false" | debconf-set-selections
dpkg-reconfigure -f noninteractive dash >> isp.log 2>&1
echo "---------------------------"
echo " * [MySQL, Postfix, openkdim & Courier]"
echo "    --> Préconfiguration"
echo "mysql-server-5.5 mysql-server/root_password password $mysql_pass" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $mysql_pass" | debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections
echo "courier-base courier-base/webadmin-configmode boolean false" | debconf-set-selections
echo "courier-ssl courier-ssl/certnotice note" | debconf-set-selections
echo "    --> Installation"
apt-get -y -qq install postfix postfix-mysql postfix-doc mysql-client mysql-server openssl getmail4 dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve opendkim opendkim-tools >> isp.log 2>&1
echo "    --> Postconfiguration (MySQL & Postfix)"
sed -i 's/bind-address = 127.0.0.1/#bind-address = 127.0.0.1/' /etc/mysql/my.cnf
/etc/init.d/mysql restart >> isp.log 2>&1
sed -i 's|#submission inet n - - - - smtpd|submission inet n - - - - smtpd|' /etc/postfix/master.cf
sed -i 's|# -o syslog_name=postfix/submission| -o syslog_name=postfix/submission|' /etc/postfix/master.cf
sed -i 's|# -o smtpd_tls_security_level=encrypt| -o smtpd_tls_security_level=encrypt|' /etc/postfix/master.cf
sed -i 's|# -o smtpd_sasl_auth_enable=yes| -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|# -o smtpd_client_restrictions=permit_sasl_authenticated,reject| -o smtpd_client_restrictions=permit_sasl_authenticated,reject|' /etc/postfix/master.cf
sed -i 's|#smtps inet n - - - - smtpd|smtps inet n - - - - smtpd|' /etc/postfix/master.cf
sed -i 's|# -o syslog_name=postfix/smtps| -o syslog_name=postfix/smtps|' /etc/postfix/master.cf
sed -i 's|# -o smtpd_tls_wrappermode=yes| -o smtpd_tls_wrappermode=yes|' /etc/postfix/master.cf
sed -i 's|# -o smtpd_sasl_auth_enable=yes| -o smtpd_sasl_auth_enable=yes|' /etc/postfix/master.cf
sed -i 's|# -o smtpd_client_restrictions=permit_sasl_authenticated,reject| -o smtpd_client_restrictions=permit_sasl_authenticated,reject|' /etc/postfix/master.cf
/etc/init.d/postfix restart >> isp.log 2>&1
echo " * [amavisd spamassassin clamav & lib Perl]"
echo "    --> Installation"
apt-get -y -qq install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl libnet-dns-perl >> isp.log 2>&1
echo "    --> Mise à jour de la base de signature ClamAV"
killall freshclam >> isp.log 2>&1
freshclam >> isp.log 2>&1
echo "    --> Postconfiguration (autostart outils AV)"
/etc/init.d/clamav-daemon start >> isp.log 2>&1
/etc/init.d/spamassassin stop >> isp.log 2>&1
update-rc.d -f spamassassin remove >> isp.log 2>&1
echo " * [Apache2, PHP5 & lib]"
echo "    --> Préconfiguration"
echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
#Bug potentiel sur les 2 commandes suivantes :
echo 'phpmyadmin phpmyadmin/dbconfig-reinstall boolean false' | debconf-set-selections
echo 'phpmyadmin phpmyadmin/dbconfig-install boolean false' | debconf-set-selections
echo 'phpmyadmin phpmyadmin/mysql/admin-pass password '$mysql_pass | debconf-set-selections
echo 'phpmyadmin phpmyadmin/mysql/app-pass password '$phpma_pass | debconf-set-selections
echo 'phpmyadmin phpmyadmin/app-password-confirm password '$phpma_pass | debconf-set-selections
echo "    --> Installation"
# libapache2-mod-suphp & libapache2-mod-ruby  retiré des dépots debian pour des raisons de sécurité
# si besoin de ruby : libapache2-passange
apt-get install -y -qq apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libruby libapache2-mod-python php5-curl php5-intl php5-memcache php5-memcached php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached libapache2-mod-passenger >> isp.log 2>&1
# Journalisation désactivée car saisie utilisateur requise pour PMA
echo "    --> Postconfiguration"
a2enmod suexec rewrite ssl actions include >> isp.log 2>&1
#Mod apacye à activer dans le cas de l'utilisation de WebDAV
#a2enmod dav_fs dav auth_digest >> isp.log 2>&1
sed -i 's|application/x-ruby|#application/x-ruby|' /etc/mime.types
echo "    --> Installation (Lib cache)"
apt-get install -y -qq php5-xcache >> isp.log 2>&1
apt-get -y -qq install libapache2-mod-fastcgi php5-fpm >> isp.log 2>&1
a2enmod actions fastcgi alias >> isp.log 2>&1
echo ServerName $HOSTNAMEFQDN >> /etc/apache2/apache2.conf
/etc/init.d/apache2 restart >> isp.log 2>&1
#L'installation de mailman est désactivée par défault (saisie utilisateur requise en cas d'installation)
#apt-get install -y mailman
#newlist mailman
#rm /etc/aliases
#cat > /etc/aliases.mailman <<"EOF"
#mailman: "|/var/lib/mailman/mail/mailman post mailman"
#mailman-admin: "|/var/lib/mailman/mail/mailman admin mailman"
#mailman-bounces: "|/var/lib/mailman/mail/mailman bounces mailman"
#mailman-confirm: "|/var/lib/mailman/mail/mailman confirm mailman"
#mailman-join: "|/var/lib/mailman/mail/mailman join mailman"
#mailman-leave: "|/var/lib/mailman/mail/mailman leave mailman"
#mailman-owner: "|/var/lib/mailman/mail/mailman owner mailman"
#mailman-request: "|/var/lib/mailman/mail/mailman request mailman"
#mailman-subscribe: "|/var/lib/mailman/mail/mailman subscribe mailman"
#mailman-unsubscribe: "|/var/lib/mailman/mail/mailman unsubscribe mailman"
#EOF
#cat /etc/aliases.backup /etc/aliases.mailman > /etc/aliases
#newaliases
#/etc/init.d/postfix restart
#ln -s /etc/mailman/apache.conf /etc/apache2/conf.d/mailman.conf
#/etc/init.d/apache2 restart
#/etc/init.d/mailman start
echo " * [FTP & quotas]"
echo "    --> Installation"
apt-get -y -qq install pure-ftpd-common pure-ftpd-mysql quota quotatool >> isp.log 2>&1
echo "    --> Postconfiguration"
sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/' /etc/default/pure-ftpd-common
echo 1 > /etc/pure-ftpd/conf/TLS >> isp.log 2>&1
mkdir -p /etc/ssl/private/ >> isp.log 2>&1
openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -subj "/C=/ST=/L=/O=/CN=$(hostname -f)" -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem >> isp.log 2>&1
chmod 600 /etc/ssl/private/pure-ftpd.pem >> isp.log 2>&1
/etc/init.d/pure-ftpd-mysql restart >> isp.log 2>&1
sed -i "s/errors=remount-ro/errors=remount-ro,usrjquota=quota.user,grpjquota=quota.group,jqfmt=vfsv0/" /etc/fstab
mount -o remount / >> isp.log 2>&1
quotacheck -avugm >> isp.log 2>&1
quotaon -avug >> isp.log 2>&1
echo " * [DNS & Analytics]"
echo "    --> Installation"
apt-get install -y -qq bind9 dnsutils >> isp.log 2>&1
apt-get install -y -qq vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl >> isp.log 2>&1
echo "    --> Postconfiguration"
rm /etc/cron.d/awstats
cat > /etc/cron.d/awstats <<"EOF"
#MAILTO=root
#10 * * * * www-data/10 * * * * www-data [ -x /usr/share/awstats/tools/update.sh ] && /usr/share/awstats/tools/update.sh
# Generate static reports:
#10 03 10 * * * * www-data * * www-data [ -x /usr/share/awstats/tools/buildstatic.sh ] && /usr/share/awstats/tools/buildstatic.sh
EOF
echo ""
echo " OK"
echo ""
echo " [Jail tools & fail2ban]"
echo "    --> Installation des dépendances"
apt-get install -y -qq build-essential autoconf automake1.11 libtool flex bison debhelper binutils-gold >> isp.log 2>&1
echo "    --> Installation de Jailkit depuis les sources (v2.17)"
cd /tmp
wget http://olivier.sessink.nl/jailkit/jailkit-2.17.tar.gz >> isp.log 2>&1
tar xvfz jailkit-2.17.tar.gz >> isp.log 2>&1
cd jailkit-2.17
./debian/rules binary >> isp.log 2>&1
cd ..
dpkg -i jailkit_2.17-1_*.deb >> isp.log 2>&1
rm -rf jailkit-2.17*
echo "    --> Installation de fail2ban"
apt-get install -y -qq fail2ban >> isp.log 2>&1
echo "    --> Postconfiguration"
cat > /etc/fail2ban/jail.local <<"EOF"
[pureftpd]
enabled = true
port = ftp
filter = pureftpd
logpath = /var/log/syslog
maxretry = 3
[dovecot-pop3imap]
enabled = true
filter = dovecot-pop3imap
action = iptables-multiport[name=dovecot-pop3imap, port="pop3,pop3s,imap,imaps", protocol=tcp]
logpath = /var/log/mail.log
maxretry = 5
[sasl]
enabled = true
port = smtp
filter = sasl
logpath = /var/log/mail.log
maxretry = 3
EOF
cat > /etc/fail2ban/filter.d/pureftpd.conf <<"EOF"
[Definition]
failregex = .*pure-ftpd: \(.*@<HOST>\) \[WARNING\] Authentication failed for user.*
ignoreregex =
EOF
cat > /etc/fail2ban/filter.d/dovecot-pop3imap.conf <<"EOF"
[Definition]
failregex = (?: pop3-login|imap-login): .*(?:Authentication failure|Aborted login \(auth failed|Aborted login \(tried to use disabled|Disconnected \(auth failed|Aborted login \(\d+ authentication attempts).*rip=(?P<host>\S*),.*
ignoreregex =
EOF
/etc/init.d/fail2ban restart >> isp.log 2>&1
echo ""
echo " ______________________________________________________"
echo "|                                                      |"
echo "| 		L'installation d'ISPconfig va commencer      |"
echo "|______________________________________________________|"
echo ""
cd /tmp
wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz >> isp.log 2>&1
tar xfz ISPConfig-3-stable.tar.gz >> isp.log 2>&1
cd ispconfig3_install/install/ >> isp.log 2>&1
php -q install.php
echo ""
echo " _____________________________"
echo "|                             |"
echo "|          Tadaaa ;)          |"
echo "|_____________________________|"

#!/bin/bash

install_initial_tools() {
	echo "---------------------------"
	echo " >> [INSTALLATION DES DEPENDANCES]"
	echo "        --> Installation des outils d'administration initiaux."
	apt-get -qy install ssh debconf-utils dnsutils unzip rkhunter binutils sudo bzip2 openssl zip ntp ntpdate 2>&1 | logmanager
}


go_dash() {
	echo "        --> Reconfiguration du terminal vers DASH"
	echo "dash dash/sh boolean false" | debconf-set-selections
	dpkg-reconfigure -f noninteractive dash 2>&1 | logmanager
}


install_mysql() {
	echo "mysql-server-5.5 mysql-server/root_password password $mysql_pass" | debconf-set-selections
	echo "mysql-server-5.5 mysql-server/root_password_again password $mysql_pass" | debconf-set-selections
	apt-get -qy install mysql-client mysql-server 2>&1 | logmanager
	sed -i 's/bind-address = 127.0.0.1/#bind-address = 127.0.0.1/' /etc/mysql/my.cnf
	/etc/init.d/mysql restart 2>&1 | logmanager
}


install_postfix() {
	echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
	echo "postfix postfix/mailname string $HOSTNAMEFQDN" | debconf-set-selections
	apt-get -qy install postfix postfix-mysql postfix-doc 2>&1 | logmanager
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
	/etc/init.d/postfix restart 2>&1 | logmanager
}


install_MTA() {
	case $MTA in
		"courier")
	  		echo "courier-base courier-base/webadmin-configmode boolean false" | debconf-set-selections
			echo "courier-ssl courier-ssl/certnotice note" | debconf-set-selections
			apt-get -qy install courier-authdaemon courier-authlib-mysql courier-pop courier-pop-ssl courier-imap courier-imap-ssl libsasl2-2 libsasl2-modules libsasl2-modules-sql sasl2-bin libpam-mysql courier-maildrop > /dev/null 2>&1
			sed -i 's/START=no/START=yes/' /etc/default/saslauthd
			cd /etc/courier
			rm -f /etc/courier/imapd.pem
			rm -f /etc/courier/pop3d.pem
			rm -f /usr/lib/courier/imapd.pem
			rm -f /usr/lib/courier/pop3d.pem
			sed -i "s/CN=localhost/CN=${CFG_HOSTNAME_FQDN}/" /etc/courier/imapd.cnf
			sed -i "s/CN=localhost/CN=${CFG_HOSTNAME_FQDN}/" /etc/courier/pop3d.cnf
			mkimapdcert > /dev/null 2>&1
			mkpop3dcert > /dev/null 2>&1
			ln -s /usr/lib/courier/imapd.pem /etc/courier/imapd.pem
			ln -s /usr/lib/courier/pop3d.pem /etc/courier/pop3d.pem
			service courier-imap-ssl restart > /dev/null
			service courier-pop-ssl restart > /dev/null
			service courier-authdaemon restart > /dev/null
			service saslauthd restart > /dev/null
			echo "done!"
			;;
		"dovecot")
			echo "            --> Préconfiguration"
			echo "courier-base courier-base/webadmin-configmode boolean false" | debconf-set-selections
			echo "courier-ssl courier-ssl/certnotice note" | debconf-set-selections
			echo "            --> Installation"
			apt-get -qy install getmail4 dovecot-imapd dovecot-pop3d dovecot-mysql dovecot-sieve 2>&1 | logmanager
			;;
	esac
}


install_antivirus() {
	echo "    * [amavisd spamassassin clamav & lib Perl]"
	echo "            --> Installation"
	apt-get -qy install amavisd-new spamassassin clamav clamav-daemon zoo unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl libnet-dns-perl 2>&1 | logmanager 
	echo "            --> Mise à jour de la base de signature ClamAV"
	killall freshclam 2>&1 | logmanager
	#freshclam 2>&1 | logmanager 
	echo "            --> Postconfiguration (autostart outils AV)"
	/etc/init.d/clamav-daemon start 2>&1 | logmanager
	/etc/init.d/spamassassin stop 2>&1 | logmanager
	update-rc.d -f spamassassin remove 2>&1 | logmanager
}



install_apache_php() {
	echo "    * [Apache2, PHP5 & lib]"
	echo "            --> Préconfiguration"
	echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
	#Bug potentiel sur les 2 commandes suivantes :
	echo 'phpmyadmin phpmyadmin/dbconfig-reinstall boolean false' | debconf-set-selections
	echo 'phpmyadmin phpmyadmin/dbconfig-install boolean false' | debconf-set-selections
	echo 'phpmyadmin phpmyadmin/mysql/admin-pass password '$mysql_pass | debconf-set-selections
	echo 'phpmyadmin phpmyadmin/mysql/app-pass password '$phpma_pass | debconf-set-selections
	echo 'phpmyadmin phpmyadmin/app-password-confirm password '$pma_pass | debconf-set-selections
	echo "            --> Installation"
	# libapache2-mod-suphp & libapache2-mod-ruby  retiré des dépots debian pour des raisons de sécurité
	# si besoin de ruby : libapache2-passange
	apt-get install -qy apache2 apache2.2-common apache2-doc apache2-mpm-prefork apache2-utils libexpat1 ssl-cert libapache2-mod-php5 php5 php5-common php5-gd php5-mysql php5-imap phpmyadmin php5-cli php5-cgi libapache2-mod-fcgid apache2-suexec php-pear php-auth php5-mcrypt mcrypt php5-imagick imagemagick libruby libapache2-mod-python php5-curl php5-intl php5-memcache php5-memcached php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl memcached libapache2-mod-passenger 2>&1 | logmanager 
	if [ $ruby == "true" ]; then
			apt-get install -qy libapache2-passange 2>&1 | logmanager
	fi
	if [ $webDAV == "true" ]; then
		a2enmod dav_fs dav auth_digest 2>&1 | logmanager
	fi
	echo "            --> Postconfiguration"
	a2enmod suexec rewrite ssl actions include 2>&1 | logmanager
	sed -i 's|application/x-ruby|#application/x-ruby|' /etc/mime.types
	echo "            --> Installation (Lib cache)"
	apt-get install -qy php5-xcache 2>&1 | logmanager
	apt-get -qy install libapache2-mod-fastcgi php5-fpm 2>&1 | logmanager
	a2enmod actions fastcgi alias 2>&1 | logmanager
	echo ServerName $HOSTNAMEFQDN >> /etc/apache2/apache2.conf
	/etc/init.d/apache2 restart 2>&1 | logmanager
}


install_ftp() {
	echo "    * [FTP & quotas]"
	echo "            --> Installation"
	apt-get -qy install pure-ftpd-common pure-ftpd-mysql 2>&1 | logmanager
	echo "            --> Postconfiguration"
	sed -i 's/VIRTUALCHROOT=false/VIRTUALCHROOT=true/' /etc/default/pure-ftpd-common
	echo 1 > /etc/pure-ftpd/conf/TLS
	mkdir -p /etc/ssl/private/
	openssl req -x509 -nodes -days 7300 -newkey rsa:2048 -subj "/C=/ST=/L=/O=/CN=$(hostname -f)" -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem >> isp.log 2>&1
	chmod 600 /etc/ssl/private/pure-ftpd.pem 2>&1 | logmanager
	/etc/init.d/pure-ftpd-mysql restart 2>&1 | logmanager

}


install_quotas() {
	apt-get -qy install quota quotatool 2>&1 | logmanager
	if [ `cat /etc/fstab | grep ',usrjquota=aquota.user,grpjquota=aquota.group,jqfmt=vfsv0' | wc -l` -eq 0 ]; then
		sed -i 's/errors=remount-ro/errors=remount-ro,usrjquota=aquota.user,grpjquota=aquota.group,jqfmt=vfsv0/' /etc/fstab
		mount -o remount / 2>&1 | logmanager
		quotacheck -avugm 2>&1 | logmanager
		quotaon -avug 2>&1 | logmanager
  	fi
}

	
install_dns() {
	echo "    * [DNS & Analytics]"
	echo "            --> Installation"
	apt-get install -qy bind9 dnsutils 2>&1 | logmanager
}


install_analytics() {
	apt-get install -qy vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl 2>&1 | logmanager
	echo "            --> Postconfiguration"
	sed -i 's/^/#/' /etc/cron.d/awstats
}


install_jailkit() {
	echo "    * [Jail tools & fail2ban]"
	echo "            --> Installation des dépendances"
	apt-get install -qy build-essential autoconf automake1.11 libtool flex bison debhelper binutils-gold 2>&1 | logmanager
	echo "            --> Installation de Jailkit depuis les sources (v2.17)"
	cd /tmp
	wget http://olivier.sessink.nl/jailkit/jailkit-2.17.tar.gz 2>&1 | logmanager
	tar xfz jailkit-2.17.tar.gz 2>&1 | logmanager
	cd jailkit-2.17
	./debian/rules binary 2>&1 | logmanager
	cd ..
	dpkg -i jailkit_2.17-1_amd64.deb 2>&1 | logmanager
	rm -rf jailkit-2.17*
}

install_fail2ban() {
	echo "            --> Installation de fail2ban"
	apt-get install -qy fail2ban 2>&1 | logmanager
	echo -e "            --> Postconfiguration\n"

	case $MTA in
		"courier")
			cat > /etc/fail2ban/jail.local <<EOF
[courierpop3]
enabled = true
port = pop3
filter = courierpop3
logpath = /var/log/mail.log
maxretry = 5

[courierpop3s]
enabled = true
port = pop3s
filter = courierpop3s
logpath = /var/log/mail.log
maxretry = 5

[courierimap]
enabled = true
port = imap2
filter = courierimap
logpath = /var/log/mail.log
maxretry = 5

[courierimaps]
enabled = true
port = imaps
filter = courierimaps
logpath = /var/log/mail.log
maxretry = 5

EOF

			cat > /etc/fail2ban/filter.d/courierpop3.conf <<EOF
[Definition]
failregex = pop3d: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

			cat > /etc/fail2ban/filter.d/courierpop3s.conf <<EOF
[Definition]
failregex = pop3d-ssl: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

			cat > /etc/fail2ban/filter.d/courierimap.conf <<EOF
[Definition]
failregex = imapd: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF

			cat > /etc/fail2ban/filter.d/courierimaps.conf <<EOF
[Definition]
failregex = imapd-ssl: LOGIN FAILED.*ip=\[.*:<HOST>\]
ignoreregex =
EOF
			;;

		"dovecot")
			cat > /etc/fail2ban/jail.local <<EOF
[dovecot-pop3imap]
enabled = true
filter = dovecot-pop3imap
action = iptables-multiport[name=dovecot-pop3imap, port="pop3,pop3s,imap,imaps", protocol=tcp]
logpath = /var/log/mail.log
maxretry = 5

EOF
			cat > /etc/fail2ban/filter.d/dovecot-pop3imap.conf <<EOF
[Definition]
failregex = (?: pop3-login|imap-login): .*(?:Authentication failure|Aborted login \(auth failed|Aborted login \(tried to use disabled|Disconnected \(auth failed|Aborted login \(\d+ authentication attempts).*rip=(?P<host>\S*),.*
ignoreregex =
EOF
		;;
  	esac
	cat > /etc/fail2ban/jail.local <<EOF
[sasl]
enabled = true
port = smtp
filter = sasl
logpath = /var/log/mail.log
maxretry = 5

[pureftpd]
enabled = true
port = ftp
filter = pureftpd
logpath = /var/log/syslog
maxretry = 3
EOF
	cat > /etc/fail2ban/filter.d/pureftpd.conf <<"EOF"
[Definition]
failregex = .*pure-ftpd: \(.*@<HOST>\) \[WARNING\] Authentication failed for user.*
ignoreregex =
EOF
	/etc/init.d/fail2ban restart 2>&1 | logmanager
}


install_mailman() {
	#(saisie utilisateur requise en cas d'installation)
	apt-get install -qy mailman 
	newlist mailman
	rm /etc/aliases
	cat > /etc/aliases.mailman <<"EOF"
	mailman: "|/var/lib/mailman/mail/mailman post mailman"
	mailman-admin: "|/var/lib/mailman/mail/mailman admin mailman"
	mailman-bounces: "|/var/lib/mailman/mail/mailman bounces mailman"
	mailman-confirm: "|/var/lib/mailman/mail/mailman confirm mailman"
	mailman-join: "|/var/lib/mailman/mail/mailman join mailman"
	mailman-leave: "|/var/lib/mailman/mail/mailman leave mailman"
	mailman-owner: "|/var/lib/mailman/mail/mailman owner mailman"
	mailman-request: "|/var/lib/mailman/mail/mailman request mailman"
	mailman-subscribe: "|/var/lib/mailman/mail/mailman subscribe mailman"
	mailman-unsubscribe: "|/var/lib/mailman/mail/mailman unsubscribe mailman"
EOF
	cat /etc/aliases.backup /etc/aliases.mailman > /etc/aliases
	newaliases
	/etc/init.d/postfix restart
	ln -s /etc/mailman/apache.conf /etc/apache2/conf.d/mailman.conf
	/etc/init.d/apache2 restart
	/etc/init.d/mailman start
}


Install_Webmail() {
  case $webmail in
	"roundcube")
		echo "    * [Webmail : Roundcube]"
		echo "            --> Pré-configuration"
	  	echo "roundcube-core roundcube/dbconfig-install boolean true" | debconf-set-selections
	  	echo "roundcube-core roundcube/database-type select mysql" | debconf-set-selections
	  	echo "roundcube-core roundcube/mysql/admin-pass password $mysql_pass" | debconf-set-selections
	  	echo "roundcube-core roundcube/db/dbname string roundcube" | debconf-set-selections
	  	echo "roundcube-core roundcube/mysql/app-pass password $roundcube_pass" | debconf-set-selections
	  	echo "roundcube-core roundcube/app-password-confirm password $roundcube_pass" | debconf-set-selections
	  	echo "            --> Installation"
	  	apt-get -qy install roundcube roundcube-mysql 2>&1 | logmanager
	  	echo "            --> Post-Configuration"
	  	sed -i '1iAlias /webmail /var/lib/roundcube' /etc/roundcube/apache.conf
	  	sed -i "s/\$rcmail_config\['default_host'\] = '';/\$rcmail_config\['default_host'\] = 'localhost';/" /etc/roundcube/main.inc.php
	  	;;
	"squirrelmail")
		echo "    * [Webmail : Squirrelmail]"
		echo "            --> Pré-configuration"
	  	echo "dictionaries-common dictionaries-common/default-wordlist select american (American English)" | debconf-set-selections
	  	echo "            --> Installation"
	  	apt-get -qy install squirrelmail wamerican 2>&1 | logmanager
	  	echo "            --> Post-Configuration"
	  	ln -s /etc/squirrelmail/apache.conf /etc/apache2/sites-enabled/squirrelmail
	  	sed -i 1d /etc/squirrelmail/apache.conf
	  	sed -i '1iAlias /webmail /usr/share/squirrelmail' /etc/squirrelmail/apache.conf
	  	cat >> /etc/squirrelmail/apache.conf <<"EOF"
<Location /webmail>
        <IfModule suphp_module>
                suPHP_Engine Off
                AddHandler php5-script  .php
        </IfModule>
        php_admin_value open_basedir "/usr/share/squirrelmail/:/etc/squirrelmail:/usr/share/squirrelmail/config/:/etc/mailname/:/var/lib/squirrelmail/data:/var/spool/squirrelmail/attach"
</Location>

EOF

	case $MTA in
		"courier")
		  	sed -i 's/$imap_server_type       = "other";/$imap_server_type       = "courier";/' /etc/squirrelmail/config.php
		  	sed -i 's/$optional_delimiter     = "detect";/$optional_delimiter     = ".";/' /etc/squirrelmail/config.php
		  	sed -i 's/$default_folder_prefix          = "";/$default_folder_prefix          = "INBOX.";/' /etc/squirrelmail/config.php
		  	sed -i 's/$trash_folder                   = "INBOX.Trash";/$trash_folder                   = "Trash";/' /etc/squirrelmail/config.php
		  	sed -i 's/$sent_folder                    = "INBOX.Sent";/$sent_folder                    = "Sent";/' /etc/squirrelmail/config.php
		  	sed -i 's/$draft_folder                   = "INBOX.Drafts";/$draft_folder                   = "Drafts";/' /etc/squirrelmail/config.php
		  	sed -i 's/$default_sub_of_inbox           = true;/$default_sub_of_inbox           = false;/' /etc/squirrelmail/config.php
		  	sed -i 's/$delete_folder                  = false;/$delete_folder                  = true;/' /etc/squirrelmail/config.php
		  	;;
		"dovecot")
		  	sed -i 's/$imap_server_type       = "other";/$imap_server_type       = "dovecot";/' /etc/squirrelmail/config.php
		  	sed -i 's/$trash_folder                   = "INBOX.Trash";/$trash_folder                   = "Trash";/' /etc/squirrelmail/config.php
		  	sed -i 's/$sent_folder                    = "INBOX.Sent";/$sent_folder                    = "Sent";/' /etc/squirrelmail/config.php
		  	sed -i 's/$draft_folder                   = "INBOX.Drafts";/$draft_folder                   = "Drafts";/' /etc/squirrelmail/config.php
		  	sed -i 's/$default_sub_of_inbox           = true;/$default_sub_of_inbox           = false;/' /etc/squirrelmail/config.php
		  	sed -i 's/$delete_folder                  = false;/$delete_folder                  = true;/' /etc/squirrelmail/config.php
		  	;;
	esac
	  ;;
  esac
  service apache2 restart 2>&1 | logmanager
}

isp_install() {
	echo " ______________________________________________________"
	echo "|                                                      |"
	echo "|         L'installation d'ISPconfig va commencer      |"
	echo -e "|______________________________________________________|\n"
	cd /tmp
	wget http://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz 2>&1 | logmanager
	tar xfz ISPConfig-3-stable.tar.gz 2>&1 | logmanager
	cd ispconfig3_install/install/
	php -q install.php
}

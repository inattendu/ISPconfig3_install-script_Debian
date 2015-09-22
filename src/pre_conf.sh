#!/bin/bash

conf_name() {
	echo " >> [PREPARATION DU SYSTEME]"
	echo "        --> Fichier HOSTS"
	rm /etc/hosts
	rm /etc/hostname
	HOSTNAMEFQDN=$HOSTNAME'.'$DOMAIN
	echo -e '127.0.0.1\t\t'$HOSTNAMEFQDN'\t'$HOSTNAME'\t localhost' >> /etc/hosts
	echo -e $serverIP'\t\t'$HOSTNAMEFQDN'\t'$HOSTNAME >> /etc/hosts
	echo "        --> Fichier HOSTNAME"
	echo $HOSTNAMEFQDN > /etc/hostname
	echo "        --> Validation des modifications"
	/etc/init.d/hostname.sh
}


conf_sources() {
	echo "        --> Actualisation des sources"
	cat > /etc/apt/sources.list <<EOF
		deb http://ftp.fr.debian.org/debian/ jessie main contrib non-free
		deb http://security.debian.org/ jessie/updates main contrib non-free
		deb http://ftp.fr.debian.org/debian/ jessie-updates main contrib non-free
EOF
}

connect_test() {
	echo "        --> test : résolution DNS & Connection internet"
	  ping -q -c 3 www.debian.org > /dev/null 2>&1
	  if [ ! "$?" -eq 0 ]; then
	  	clear
		echo "ERREUR: www.debian.org injoignable, vérifier la connection à internet ainsi que la résolution DNS."
		exit 1;
	  fi
}

conf_maj(){
	echo "        --> Mise à jour système"
	apt-get -q clean 2>&1 | logmanager
	apt-get -q update 2>&1 | logmanager
	apt-get -q -y dist-upgrade 2>&1 | logmanager
	apt-get -q -y autoremove --purge 2>&1 | logmanager
}

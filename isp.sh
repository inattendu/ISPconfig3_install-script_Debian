#!/bin/bash

#Poser la question pour freshclam pendant l'install, temporairement désactivé pour test isp_install.sh ligne 86

source isp.conf
source src/timestamp.sh
source src/pre_conf.sh
source src/isp_install.sh

if [ -f /etc/debian_version ] || [$SafeExec !== "true"]; then
	echo -e " _____________________________\n|                             |\n|  Scrip de déploiement v1.0  |\n| by inattendu                |\n|_____________________________|\n\n"
	conf_name()
  	conf_sources()
	connect_test()
	conf_maj()
	conf_maj()
	install_initial_tools()
	go_dash()
	install_mysql()
	install_postfix()
	install_MTA()
	install_antivirus()
	install_apache&php()
	install_ftp()
	if [ $quotas_install == "true" ]; then
		install_quotas()
  	fi
	install_dns()
	install_analytics()
	if [ $jailkit_install == "true" ]; then
		install_jailkit()
  	fi
	install_fail2ban()
	if [ $mailman_install == "true" ]; then
		install_mailman() 
	if [ $webmail_install == "true" ]; then
		Install_Webmail()
	fi
	isp_install()
else
	echo "Fichier /etc/debian_version non trouvé"
	echo "ce script est destiné à Debian 8 (Jessie)"
fi
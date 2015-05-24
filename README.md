# Déploiement silentieux d'ISPconfig3 (Debian Jessie)

## Scénario
 L'objectif est le déploiement d'un environnement serveur ISPconfig fonctionnel le plus silentieusement possible.
 
 A l'heure d'aujourd'hui, il s'agit d'un environnement STANDALONE.
 
## Usage
 Editer les variables placées en début de fichier : 
 
   serverIP=192.168.222.19
   
   HOSTNAMESHORT=proxmox
   
   HOSTNAMEFQDN=proxmox.inattendu-lab.org
   
   mysql_pass=toor
   
   phpma_pass=toor

 chmod +x isp.sh && ./isp.sh
   La quasi totalité des retours sont stockés dans le fichier isp.log

## Working
  * Installation silentieuse des dépendances
  
## ToDo
  * Corriger certains retour de commandes qui échappent à l'écriture dans isp.log
  * Ajout timestamp au fichier journal
  * Mise en argument des variables
  * Installation ISPconfig3 en mode silent
  * Tweak de l'install (Wizard || arg)
  * installation d'un webmail (Roundcube)

# Déploiement silencieuse d'ISPconfig3 (Debian 8)

## Scénario
 Déploiement d'un environnement serveur ISPconfig STANDALONE<br/>
 
## Usage
 * Editer le fichier isp.conf
 * Rendre le script executable & le lancer.
  chmod +x isp.sh && ./isp.sh<br/>
   Les retours sont stockés dans le fichier isp.log

## Working
  * Installation silentieuse
  * Journalisation & Timestamp >> isp.log

## Known Bug
  * Installation de JailKit depuis les sources ne se passe pas comme prévu.
  
## ToDo
  * Tweak de l'install (ARG)
    ** Wizard (dialog)
    ** Silent
  * Installation ISPconfig3 en mode silent
  * installation d'un webmail (Roundcube / Horde)
  * Apache : 
  	** Redirect Auto $:8080 vers HTTPS

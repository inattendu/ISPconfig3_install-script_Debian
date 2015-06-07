# Déploiement silencieuse d'ISPconfig3 (Debian 8)

## Scénario
 Déploiement d'un environnement serveur ISPconfig STANDALONE<br/>
 
## Usage
 * Editer le fichier isp.conf
 * Rendre le script executable & le lancer.
  chmod +x isp.sh && ./isp.sh<br/>

## Working
  * Installation silentieuse
  * Journalisation & Timestamp >> /var/log/isp_installer.log (emplacement modifiable)
  * Détection pré-requis réseau (DNS & GW)
  * Choix de l'installation ou non de composants optionels dans le fichier de conf
  * Choix de l'installation optionelle parmis deux MTA (courier / dovecot) et deux webmails (SquirelMail / RoundCube)

## Known Bug
  * Installation de Roundcube n'est pas encore fonctionelle (squirelmail défini par défaut).
  * Une partie des logs est écrite dans /tmp/ à partir de la ligne 72 du fichier isp_install.sh
  
## ToDo
  * Tweak de l'install (ARG)<br/>
    ** Wizard (dialog)<br/>
    ** Silent
  * Installation ISPconfig3 en mode silent
  * Ajout de Horde aux webmails possibles
  * Apache :<br/>
  	** Redirect Auto $:8080 vers HTTPS
  * Gestion d'erreur.
  * Retour test connection fichier journal
  * Segmentation visuelle fichier journal
  * Tweak Alias URL "webmail"
  * Fix journalisation (fonctions muettes)
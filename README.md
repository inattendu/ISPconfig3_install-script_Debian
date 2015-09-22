# Déploiement silencieuse d'ISPconfig3 (Debian 8)

## Scénario
 Déploiement d'un environnement serveur ISPconfig STANDALONE<br/>
 
BETA USE, please read theses sripts before anthing else.

## Usage
 * Editer le fichier isp.conf
 * Rendre le script executable & le lancer.
  chmod +x install.sh && ./install.sh<br/>

## Working
  * Installation silentieuse
  * Journalisation & Timestamp >> /var/log/isp_installer.log (emplacement modifiable)
  * Détection pré-requis réseau (DNS & GW)
  * Choix de l'installation ou non de composants optionels dans le fichier de conf
  * Choix de l'installation optionelle parmis deux MTA (courier / dovecot) et un webmail (SquirelMail)

## Known Bug
  * Installation de Horde n'est pas encore fonctionelle (squirelmail défini par défaut).
  
## ToDo
  * Tweak de l'install (ARG)<br/>
    ** Wizard (dialog)<br/>
    ** Silent
  * Installation ISPconfig3 en mode silent.
  * Séparation des logs d'installation (ajout arg logmanager).<br/>
    **ISP_loader.log --> choix des composants & réeussite / erreurs<br/>
    **XX_SubInstaller.log --> logs & réussite / erreurs par composants
  * Ajout de Horde & Roundcube aux webmails possibles.
  * Apache :<br/>
  	** Redirect Auto $:8080 vers HTTPS
  * Retour test connection fichier journal
  * Tweak Alias URL "webmail"
  * Vérifier écriture hostname.domain depuis modification fichier de conf
  * Expect ISPconfig / Mailman
  * Retour d'installation, MAIL & POST HTTP
  * Check package (Déjà présent)
  * Install horde --> logmanager

## Just Done
  * Déploiement de MariaDB au lieux de MySQL + patch conf post-install (testing)
  * Ajout paquet expect
  * Retrait de paquets doublon dans les phases d'installation
  * PhpMyadmin optionnel
  * Choix update ClamAV pendant l'installation
  * Expect Horde
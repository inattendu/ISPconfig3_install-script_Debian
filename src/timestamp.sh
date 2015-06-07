#!/bin/bash

#Fonction TimeStamp

## 'cmd' 2>&1 | adddate >> isp.log 2>&1
## Retourne toutes les sorties dans le fichier isp.log sous la forme : 
## JJ/MM/AA HH:MM:SS | retour_cmd

adddate() {
    while IFS= read -r line; do
        echo "$(date +'%d/%m/%y %k:%M:%S |') $line"
    done
}
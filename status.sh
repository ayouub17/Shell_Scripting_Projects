#!/bin/bash
# Projet : Script de diagnostic système
# Auteur : AYOUB ELHANAFI
# Filiere : DSE



clear

echo "================================================================================="
echo "                   BIENVENUE DANS LE SCRIPT SYSTEME DE DEVAMINE                  "
echo "                                                            "
echo "================================================================================="
echo

read -p "Veuillez entrer votre prénom : " utilisateur
echo
echo "Bonjour $utilisateur, voici un diagnostic complet du système."
sleep 1

# 1. Informations système de base
echo
echo "------------------------- INFORMATIONS SYSTÈME -------------------------"
echo
echo "Nom du serveur : $(hostname)"
echo "Système d'exploitation : $(lsb_release -d 2>/dev/null | cut -f2-)"
echo "Noyau Linux : $(uname -r)"
echo "Architecture : $(uname -m)"

# 2. Date et heure
echo
echo "------------------------- DATE ET HEURE ACTUELLES -------------------------"
echo
date "+Date : %A %d %B %Y | Heure : %H:%M:%S (%Z)"
echo "Depuis le démarrage : $(uptime -s)"

# 3. Mémoire
echo
echo "------------------------- INFORMATIONS MÉMOIRE -------------------------"
echo
free -h | awk '
NR==1 {print "          " $0}
NR==2 {print "Total   : " $2 " | Utilisé : " $3 " (" $3/$2*100 "%) | Libre : " $4}
NR==3 {print "Swap    : " $2 " | Utilisé : " $3 " (" $3/$2*100 "%)"}' 

# 4. Disque
echo
echo "------------------------- ESPACE DISQUE -------------------------"
echo
df -h --output=source,size,used,pcent,target | grep '^/dev/' | \
awk '{printf "%-15s %-8s %-8s %-8s %s\n", $1, $2, $3, $4, $5}'

# 5. CPU
echo
echo "------------------------- INFORMATIONS PROCESSEUR -------------------------"
echo
echo "Modèle : $(grep "model name" /proc/cpuinfo | head -n1 | cut -d':' -f2 | sed 's/^[ \t]*//')"
echo "Cœurs : $(nproc)"
echo "Charge : $(uptime | awk -F'load average: ' '{print $2}')"

# 6. Réseau
echo
echo "------------------------- INFORMATIONS RÉSEAU -------------------------"
echo
echo "Adresse IP : $(hostname -I | awk '{print $1}')"
echo "Passerelle : $(ip route | grep default | awk '{print $3}')"
echo "DNS : $(grep nameserver /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')"

# 7. Utilisateurs
echo
echo "------------------------- UTILISATEURS CONNECTÉS -------------------------"
echo
who -H

# 8. Services
echo
echo "------------------------- SERVICES IMPORTANTS -------------------------"
echo
services=("sshd" "nginx" "apache2" "mysql" "postgresql")
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service 2>/dev/null; then
        status="ACTIF"
    else
        status="INACTIF"
    fi
    echo "- $service : $status"
done

# 9. Mises à jour
echo
echo "------------------------- MISES À JOUR -------------------------"
echo
if command -v apt &> /dev/null; then
    updates=$(apt list --upgradable 2>/dev/null | wc -l)
    echo "Paquets à mettre à jour : $((updates-1))"
elif command -v yum &> /dev/null; then
    updates=$(yum list updates | wc -l)
    echo "Paquets à mettre à jour : $((updates-1))"
else
    echo "Gestionnaire de paquets non reconnu"
fi

# 10. Processus
echo
echo "------------------------- PROCESSUS GOURMANDS -------------------------"
echo
echo "Par CPU :"
ps -eo pid,user,%cpu,cmd --sort=-%cpu | head -n 6
echo
echo "Par mémoire :"
ps -eo pid,user,%mem,cmd --sort=-%mem | head -n 6

# 11. Températures
echo
echo "------------------------- CAPTEURS DE TEMPÉRATURE -------------------------"
echo
if sensors &> /dev/null; then
    sensors | grep Core
elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    echo "Température CPU : $((temp/1000))°C"
else
    echo "Information non disponible"
fi

# 12. Docker
if command -v docker &> /dev/null; then
    echo
    echo "------------------------- INFORMATIONS DOCKER -------------------------"
    echo
    echo "Conteneurs actifs : $(docker ps -q | wc -l)"
    echo "Conteneurs total : $(docker ps -aq | wc -l)"
fi

echo
echo "================================================================================="
echo "          DIAGNOSTIC TERMINÉ - MERCI $utilisateur !"
echo "          Dernière exécution : $(date)"
echo "================================================================================="
#!/bin/bash
# Ajoute un saut de ligne, puis une ligne de séparation + date/heure
echo -e "\n========== $(date '+%Y-%m-%d %H:%M:%S')\n" >>/root/cocadmin/maj_apt.log

#/usr/bin/ansible-playbook -i /home/user/ansible/hosts /home/user/ansible/maj_apt.yml >> /var/log/ansible-maj.log 2>&1
/root/.local/bin/ansible-playbook -i /root/cocadmin/hosts_all /root/cocadmin/maj_apt.yml >>/root/cocadmin/maj_apt.log 2>&1

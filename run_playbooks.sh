#!/bin/bash 
# This script runs the playbooks on host0

echo ""
echo "                   _       _     "
echo "                  | |     | |    "
echo "  _ __  _   _  ___| | __ _| |__  "
echo " | '_ \| | | |/ __| |/ _\` | '_ \ "
echo " | | | | |_| | (__| | (_| | |_) |"
echo " |_| |_|\__,_|\___|_|\__,_|_.__/ "
echo -e "\n\n"

ANSIBLE_RUNDIR=`echo ~/nuclab/ansible_nuclab_basics`
cd $ANSIBLE_RUNDIR && ansible-playbook -i custom_vars/hosts.yml main.yml --vault-password-file=~/.ansible/vaultpw.txt